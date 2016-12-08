#!/usr/bin/python

import boto3
import sys
import subprocess
from subprocess import call


stdout=subprocess.Popen("/usr/bin/wget -q -O - http://169.254.169.254/latest/meta-data/instance-id", shell=True, stdout=subprocess.PIPE, )
instance_id=stdout.stdout.readlines()[0]
#inst_name = str(sys.argv[1])
act_type = str(sys.argv[1])
lb_name = ''

client = boto3.client('elb', region_name='us-east-1')


def register(instance_id, lb_name):
    response = client.register_instances_with_load_balancer(
     LoadBalancerName=lb_name,
     Instances=[
            {
                'InstanceId': instance_id
            },
        ]
    )
    return response


def deregister(instance_id, lb_name):
    response = client.deregister_instances_from_load_balancer(
     LoadBalancerName=lb_name,
     Instances=[
            {
                'InstanceId': instance_id
            },
        ]
    )
    return response


if (act_type == 'deregister'):
  result = deregister(instance_id, lb_name)
elif (act_type == 'register'):
  result = register(instance_id, lb_name)
else: result = 'use script with action arg'

print result
