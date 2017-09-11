#!/usr/bin/python

import boto3
import boto3.ec2
import subprocess
from subprocess import call
import os
import re

p = re.compile('ns[0-9+]', re.IGNORECASE)
line = 2
fromhostname=subprocess.Popen("/bin/hostname", shell=True, stdout=subprocess.PIPE, )
myhost = fromhostname.stdout.readlines()[0]

stdout=subprocess.Popen("/usr/bin/wget -q -O - http://169.254.169.254/latest/meta-data/instance-id", shell=True, stdout=subprocess.PIPE, )
hostid=stdout.stdout.readlines()[0]

#[{u'Value': 'xromeo-auscale-group', u'Key': 'aws:autoscaling:groupName'}, {u'Value': 'ip-10-31-252-78\n', u'Key': 'Name'}]
ec2 = boto3.resource('ec2', region_name='us-east-1')
for instance in ec2.instances.all():
    for tag in instance.tags:
        if 'Name' in tag['Key'] and tag['Value'] is not None:
            hostname = tag['Value'].rstrip('\n')
            if instance.id == hostid:
                if not hostname == myhost:
                    args="/bin/hostname " + hostname
                    os.system(args)
                    print hostname, instance.id, instance.private_ip_address
        if p.match(hostname):
            print hostname + " " + instance.private_ip_address + " " + str(line)
            nameserver = "nameserver " + instance.private_ip_address + "\n"
            f = open("/etc/resolv.conf", "r")
            contents = f.readlines()
            f.close()
            if not any(instance.private_ip_address in s for s in contents):
                contents.insert(line, nameserver)
            f = open("/etc/resolv.conf", "w")
            contents = "".join(contents)
            f.write(contents)
            f.close()
