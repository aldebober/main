#!/usr/bin/python
import boto3
import math
import time
import sys

ip = str(sys.argv[1])

IP_SET_ID_MANUAL_BLOCK = ''

REQUEST_PER_MINUTE_LIMIT = None

LIMIT_IP_ADDRESS_RANGES_PER_IP_MATCH_CONDITION = 1000
API_CALL_NUM_RETRIES = 3


def is_already_blocked(ip, ip_set):
    result = False

    try:
        for net in ip_set:
            ipaddr = int(''.join([ '%02x' % int(x) for x in ip.split('.') ]), 16)
            netstr, bits = net.split('/')
            netaddr = int(''.join([ '%02x' % int(x) for x in netstr.split('.') ]), 16)
            mask = (0xffffffff << (32 - int(bits))) & 0xffffffff

            if (ipaddr & mask) == (netaddr & mask):
                result = True
                break
    except Exception, e:
        pass

    return result


def waf_get_ip_set(ip_set_id):
    response = None
    waf = boto3.client('waf')

    for attempt in range(API_CALL_NUM_RETRIES):
        try:
            response = waf.get_ip_set(IPSetId=ip_set_id)
        except Exception, e:
            print e
            delay = math.pow(2, attempt)
            print "[waf_get_ip_set] Retrying in %d seconds..." % (delay)
            time.sleep(delay)
        else:
            break
    else:
        print "[waf_get_ip_set] Failed ALL attempts to call API"

    return response

def waf_update_ip_set(ip_set_id, updates_list):
    response = None

    if updates_list != []:
        waf = boto3.client('waf')
        for attempt in range(API_CALL_NUM_RETRIES):
            try:
                response = waf.update_ip_set(IPSetId=ip_set_id,
                    ChangeToken=waf.get_change_token()['ChangeToken'],
                    Updates=updates_list)
            except Exception, e:
                delay = math.pow(2, attempt)
                print "[waf_update_ip_set] Retrying in %d seconds..." % (delay)
                time.sleep(delay)
            else:
                break
        else:
            print "[waf_update_ip_set] Failed ALL attempts to call API"

    return response


def get_ip_set_already_blocked():
    print "[get_ip_set_already_blocked] Start"
    ip_set_already_blocked = []
    try:
        if IP_SET_ID_MANUAL_BLOCK != None:
            response = waf_get_ip_set(IP_SET_ID_MANUAL_BLOCK)
            if response != None:
                for k in response['IPSet']['IPSetDescriptors']:
                    ip_set_already_blocked.append(k['Value'])
    except Exception, e:
        print "[get_ip_set_already_blocked] Error getting WAF IP set"
        print e

    print "[get_ip_set_already_blocked] End"
    return ip_set_already_blocked



def update_waf(ip, ip_set_id, ip_set_already_blocked):
    updates_list = []
    waf = boto3.client('waf')
    if not is_already_blocked(ip, ip_set_already_blocked):
        updates_list.append({
                 'Action': 'INSERT',
                 'IPSetDescriptor': {
                     'Type': 'IPV4',
                     'Value': "%s/32"%ip
                 }
             })
    else:
        updates_list.append({
                 'Action': 'DELETE',
                 'IPSetDescriptor': {
                     'Type': 'IPV4',
                     'Value': "%s/32"%ip
                 }
             })


    response = waf_update_ip_set(ip_set_id, updates_list)
    return response


#print waf_get_ip_set(IP_SET_ID_MANUAL_BLOCK)

#num_blocked = update_waf_ip_set(outstanding_requesters['block'], IP_SET_ID_AUTO_BLOCK, ip_set_already_blocked)
#num_quarantined = update_waf_ip_set(outstanding_requesters['count'], IP_SET_ID_AUTO_COUNT, ip_set_already_blocked)

ip_set_already_blocked = get_ip_set_already_blocked()
response = update_waf(ip, IP_SET_ID_MANUAL_BLOCK, ip_set_already_blocked)

print response
