#!/usr/bin/env python
import boto3
import sys
client = boto3.client('ec2')

if len(sys.argv) < 2:
    sys.exit('Usage: %s region_name' % sys.argv[0])
subnet_id = sys.argv[1].strip()

def check_subnet(s):
    try:
        client.describe_subnets(SubnetIds=[ s ])
    except:
        my_session = boto3.session.Session()
        my_region = my_session.region_name
        sys.exit('There is not your subnet %s in %s' %(s, my_region))


check_subnet(subnet_id)
