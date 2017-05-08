#!/usr/bin/python

import gzip
import boto3
import datetime
import time

REQUEST_PER_MINUTE_LIMIT = 10
# Fixed
LINE_FORMAT = {
    'date': 0,
    'time' : 1,
    'source_ip' : 4
}

def get_outstanding_requesters(bucket_name, key_name):
    print '[get_outstanding_requesters] Start'

    outstanding_requesters = {}
    outstanding_requesters['block'] = {}
    outstanding_requesters['count'] = {}
    result = {}
    num_requests = 0

    #--------------------------------------------------------------------------------------------------------------
    print '[get_outstanding_requesters] \tDownload file from S3'
    #--------------------------------------------------------------------------------------------------------------
    local_file_path = '/tmp/' + key_name.split('/')[-1]
    print bucket_name, key_name, local_file_path
    s3 = boto3.client('s3')
    s3.download_file(bucket_name, key_name, local_file_path)

    #--------------------------------------------------------------------------------------------------------------
    print '[get_outstanding_requesters] \tRead file content'
    #--------------------------------------------------------------------------------------------------------------
    content = gzip.open(local_file_path,'r')
    try:
        for line in content.read().split("\n"):
            try:
                if line.startswith('#'):
                    continue
                line_data = line.split('\t')
                request_key = line_data[LINE_FORMAT['date']]
                request_key += '-' + line_data[LINE_FORMAT['time']][:-3]
                request_key += '-' + line_data[LINE_FORMAT['source_ip']]
                if request_key in result.keys():
                   result[request_key] += 1
                else:
                    result[request_key] = 1
                num_requests += 1
            except Exception, e:
                print ("[get_outstanding_requesters] \t\tError to process line: %s"%line)
    finally:
        content.close()

    #--------------------------------------------------------------------------------------------------------------
    print '[get_outstanding_requesters] \tKeep only outstanding requesters'
    #--------------------------------------------------------------------------------------------------------------
    now_timestamp_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    for k, v in result.iteritems():
        k = k.split('-')[-1]
        if v > REQUEST_PER_MINUTE_LIMIT:
            if k not in outstanding_requesters['block'].keys() or outstanding_requesters['block'][k] < v:
                outstanding_requesters['block'][k] = { 'max_req_per_min': v, 'updated_at': now_timestamp_str }

    print '[get_outstanding_requesters] End'
    return outstanding_requesters, num_requests



backet=''
gzip_logfile=''
output = get_outstanding_requesters(backet, gzip_logfile)
for ip, data in output[0]['block'].iteritems():
    print ip, data['max_req_per_min']

