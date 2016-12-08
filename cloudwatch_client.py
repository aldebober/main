#!/usr/bin/env python

import sys
import re
from boto.ec2 import cloudwatch
from boto.utils import get_instance_metadata
import subprocess
from subprocess import call
import json
from string import Template
import pycurl
import cStringIO
import xml.etree.ElementTree as ET



def curl(url, headers=None, user=None, password=None):
    buf = cStringIO.StringIO()
    c = pycurl.Curl()
    if headers != None:
        c.setopt(pycurl.HTTPHEADER, headers)
    if user != None and password != None:
        c.setopt(pycurl.USERPWD, '%s:%s' % (user, password))
    c.setopt(c.URL, url)
    c.setopt(c.WRITEFUNCTION, buf.write)
    c.perform()
    return buf.getvalue()


def get_newrelic_metric(name = 'api'):
   newrelic = {}
   url = 'https://api.newrelic.com/v2/applications.json'
   headers = ['X-Api-Key: YOUR_API_KEY']
   json_data=curl(url, headers)
   data = json.loads(json_data)
   for key in data["applications"]:
        if (key['name'] == name):
            newrelic['rpm'] =key["application_summary"]["throughput"]
            newrelic['response_time'] = key["application_summary"]["response_time"]
            newrelic['error_rate'] = key["application_summary"]["error_rate"]
            newrelic['apdex'] = key["application_summary"]["apdex_score"]
#        print key['name'], key["application_summary"]["response_time"], key["application_summary"]["throughput"]
   return newrelic


def collect_tomcat_memory():
    url = 'http://localhost:8080/manager/status?XML=true'
    user = 'monitor'
    password = ''
    tomcat_status = curl(url, None, user, password)
    try:
        root = ET.fromstring(tomcat_status)
    except ET.ParseError as e:
        return 0
    memory = root.find('.//memory')
    free_memory = float(memory.get('free'))
    total_memory = float(memory.get('total'))
    max_memory = float(memory.get('max'))
    available_memory = free_memory + max_memory - total_memory
    used_memory = max_memory - available_memory
    data = { 'TomcatUsageMem': float((used_memory * 100)/max_memory) }
    return data


def collect_memory_usage():
    meminfo = {}
    pattern = re.compile('([\w\(\)]+):\s*(\d+)(:?\s*(\w+))?')
    with open('/proc/meminfo') as f:
        for line in f:
            match = pattern.match(line)
            if match:
                # For now we don't care about units (match.group(3))
                meminfo[match.group(1)] = float(match.group(2))
    mem_free = meminfo['MemFree'] + meminfo['Buffers'] + meminfo['Cached']
    mem_used = meminfo['MemTotal'] - mem_free
    if meminfo['SwapTotal'] != 0 :
	swap_used = meminfo['SwapTotal'] - meminfo['SwapFree'] - meminfo['SwapCached']
	swap_percent = swap_used / meminfo['SwapTotal'] * 100
    else:
	swap_percent = 0
    mem_data = {'MemUsage': mem_used / meminfo['MemTotal'] * 100,
		'SwapUsage': swap_percent }
#	print mem_used, meminfo['MemTotal'], swap_percent
    return mem_data


def collect_disk_usage():
#/dev/xvda1        15350768      6824244  8426256           45% /
    disks = {}
    pattern = re.compile('^\/dev\/(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%')
    stdout=subprocess.Popen("df -k -l --type=ext4 --type=ext3 --type=xfs --type=ext2", shell=True, stdout=subprocess.PIPE,)
    for line in stdout.stdout.readlines():
       match = pattern.match(line)
       if match:
          disks[match.group(1)] = match.group(5)
    return disks

def send_multi_metrics(instance_id, region, metrics, namespace='EC2/Memory',
                        unit='Percent'):
    cw = cloudwatch.connect_to_region(region)
    cw.put_metric_data(namespace, metrics.keys(), metrics.values(),
                       unit=unit,
                       dimensions={"InstanceId": instance_id})



if __name__ == '__main__':
    metadata = get_instance_metadata()
    instance_id = metadata['instance-id']
    region = metadata['placement']['availability-zone'][0:-1]
    try:
        newrelic = str(sys.argv[1])
    except:
        newrelic = None
    if newrelic:
        arg, val = newrelic.split('=')
        newrelic_data = get_newrelic_metric(val)
        send_multi_metrics(instance_id, region, newrelic_data, 'Newrelic/Apps', 'None')
    memory = collect_memory_usage()
    send_multi_metrics(instance_id, region, memory)
    disk = collect_disk_usage()
    send_multi_metrics(instance_id, region, disk, 'EC2/Disk')
    tomcat_mem = collect_tomcat_memory()
    send_multi_metrics(instance_id, region, tomcat_mem)
