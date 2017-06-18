#!/usr/bin/env python

# You have to add script in your cronjob
# pull_size is optional and isn't required
# threshold is amount of event when alert will be sent
# date_min is the period of time
# queries=[] is the list of queries
# Fill email addresses in def mailto()

# Requirements
# python 2.x
# pip install elasticsearch

import elasticsearch
import smtplib

url = 'http://ec2-52-58-225-203.eu-central-1.compute.amazonaws.com:5601/'
pull_size=300
threshold=0
date_min="now-10m"
date_max="now"
queries=[
 { "query": "severity_label:Error AND -(Request idm_provisioning failed) AND -(Request idm_delete failed) AND -(exited with reason: noproc) AND -(onb_check_msisdn)" }
    ]

es = elasticsearch.Elasticsearch()


def search_the_match(query):
    body = {
      "query": {
        "bool": {
          "must": [
        { "query_string": query },
                { "range": { "@timestamp": { "gte": date_min, "lte": date_max } } }
                ]
            }
        }
    }

    total = 0
    try:
        matches = es.search(index='logstash-*', request_timeout=30, size=pull_size, body=body)
        total = matches['hits']["total"]
        if total > threshold:
            hits = matches['hits']['hits']
        else:
            hits = None
    except:
        print "error while retrive search"
        hits = None
    return total, hits


def mailto(message):
   to = [ "yuriy@example.com"]
   user = 'elastic@example.com'
   smtpserver = smtplib.SMTP('localhost')
   header = 'To:' + str(','.join(to)) + '\n' + 'From: ' + user + '\n' + 'Subject:testing \n\n'
   msg = header + message + '\n\n'
   smtpserver.sendmail(user, to, msg)
   smtpserver.close()



for query in queries:
    total, hits = search_the_match(query)
    if not hits:
        print 'No matches found'
    else:
        message="Found total matches:" + str(total) + '\n\n'
        for hit in hits:
           event = hit["_source"]["@timestamp"] + '\t' + hit["_source"]['host'] + '\t' + hit["_source"]["message"]
           message += event
           uri = 'app/kibana#/doc/logstash-*/' + hit['_index'] + '/logs?id=' + hit['_id'] + '\n\n'
           message += url + uri
        mailto(message)
#        print message

