#!/usr/bin/python

from azure.storage import *
import datetime
import time
import re
import json

name = ''
key = ''
NET_epoch = datetime.datetime(0001,1,1)
UNIX_epoch = datetime.datetime(1970,1,1)
epoch_delta = (UNIX_epoch - NET_epoch).days*86400

#tc_hour_ago = (epoch_delta + int(time.time()) - 3600*24)*1000*1000*10
tc_hour_ago = (epoch_delta + int(time.time()) - 3600)*1000*1000*10
print tc_hour_ago

table_service = TableService(account_name=name, account_key=key)

f = open('/tmp/error_azure.log', 'a')
tasks = table_service.query_entities('WADLogsTable',  filter="EventTickCount gt %iL" % tc_hour_ago )
#tasks = table_service.query_entities('WADLogsTable', filter="EventTickCount gt 635186298040000000L")
for entity in tasks:
    classname = ''
    exception = ''
    print entity.Message
    lines = entity.Message.splitlines()
    classstr = re.sub("'", "", lines[0])
    source = re.sub("'", "", lines[-1])
    regex = re.findall(r'([\w,\s,.]+: )(.*)', classstr)
    regex1 = re.findall(r'(TraceSource .*$)', source)
    for i in regex:
       classname = i[0]
       exception = i[1]
    event_t = entity.EventTickCount/(1000*1000*10)
    ts = event_t - epoch_delta
    date = datetime.datetime.fromtimestamp(ts).strftime("%Y-%B-%d-%I:%M%p")
    message = "\n".join(lines)
    jsontext =  json.dumps({"date":date, "class":classname, "exception": exception, "TraceSource": regex1[0], "Message": message, "EventTickCount": entity.EventTickCount, "RoleInstance": entity.RoleInstance }, sort_keys=True)
    f.write(jsontext)
    f.write("\n")

f.close
