#!/usr/bin/env python
import os
import requests
import re
from pyelasticsearch import ElasticSearch


def push_to_es(data):
    es = ElasticSearch('http://52.14.73.76:9200/')
    es.bulk((es.index_op(doc, id=doc.pop('id')) for doc in data),
            index='bws-run',
            doc_type='logs')


def get_last_id(filename):
    with open(filename, 'r') as f:
        read_data = f.read()
    f.close()
    return read_data.strip()


def set_last_id(filename, last_id):
    with open(filename, 'w') as f:
        f.write(last_id)
    f.close()


def return_response(response):
    if response.status_code == requests.codes.ok:
        return response.json()
    else:
        message = {'status_code': response.status_code}
        try:
                response.json()
                message.update(response.json())
        except:
                pass
        return message


def events(query=None, system_id=None, group_id=None,
           min_id=None, min_time=None, max_id=None, max_time=None):

    if min_id is None:
        min_id = get_last_id('/tmp/papertrail_id')
        print min_id
    api_token = os.environ['PAPERTRAIL_API_TOKEN']
    base_uri = 'https://papertrailapp.com/api/v1'
    headers = {'X-Papertrail-Token': api_token}
    params = {'q': query,
                'system_id': system_id,
                'group_id': group_id,
                'min_id': min_id,
                'min_time_at': min_time,
                'max_id': max_id,
                'max_time_at': max_time
              }

    r = requests.get('{0}/{1}/{2}'.format(base_uri, 'events', 'search.json'),
                     headers=headers,
                     params=params)

    return return_response(r)


all_events = events("bws-run",
                    system_id=None,
                    min_id=None,
                    min_time=None,
                    max_id=None,
                    max_time=None)
p1 = re.compile('<([\d.]+)>\s-\s[\d.:]+\s\[(\w+)\]\s<<"([\w_]+)">>\s\["(\d+.\d+.\d+.\d+)"\]\s(.+)', re.I)
p2 = re.compile('<([\d.]+)>\s-\s[\d.:]+\s\[(\w+)\]\s(.+)', re.I)
last_id = None
es_data = []
count = 0
for event in all_events["events"]:
    count += 1
    es_event = {}
    last_id = event["id"]
    if(event['program'] == 'bws-run'):
        m = p1.search(event["message"])
        l = p2.search(event["message"])
        if m:
#2017-03-07T15:25:14+03:00 775746138723827712 WIND-bws-run-i-03b67f4685d5bf706 0.14997.2509 IT_fcce3e2c3ba0e5761cf1c81b2197001e8f44906d 130.0.210.169 {<<"online">>} -> [sys]
            es_event = {'id': event["id"], 'name': event["source_name"], 'time': event["received_at"], 'bws_thread':m.group(1), 'ithash': m.group(3), 'client_ip': m.group(4), 'message': m.group(5) }
#            print event["received_at"], event["id"], event["source_name"],  m.group(1), m.group(3), m.group(4), m.group(5)
        elif l:
            es_event = {'id': event["id"], 'name': event["source_name"], 'time': event["received_at"], 'bws_thread':l.group(1), 'message': l.group(3)  }
#            print event["received_at"], event["id"], event["source_name"],  l.group(1), l.group(3)
        else:
            es_event = {'id': event["id"], 'name': event["source_name"], 'time': event["received_at"], 'message': event["message"]  }
#            print event["message"]
    #elif(event['program'] == 'bws'):
    #        print event["received_at"], event["id"], event["source_name"], event["message"]
    if(es_event):
        es_data.append(es_event)

if (es_data):
    push_to_es(es_data)

print "Count: %d\tLast id: %s" % (count, last_id)

if last_id is not None:
    set_last_id('/tmp/papertrail_id', last_id)
