#!/usr/bin/python

import boto3
import sys
import subprocess
from subprocess import call
import datetime

myhost = 'TEST_ENV'

hour = datetime.datetime.now().hour
today = datetime.date.today().strftime("%d%m%Y%I")
desc = myhost + '_' + str(today) + '_' + str(hour)
stdout = subprocess.Popen("/usr/bin/wget -q -O - http://169.254.169.254/latest/meta-data/instance-id", shell=True, stdout=subprocess.PIPE, )
image_id = stdout.stdout.readlines()[0]


def create_img(image_id, desc):
    client = boto3.client('ec2', region_name='us-east-1')
    response = client.create_image(
     InstanceId=image_id,
     Name=desc,
     Description=desc,
     NoReboot=True,
    )
    return response


def create_lc(lc_name, image_id, ssh_key, security, instance_type):
    client = boto3.client('autoscaling', region_name='us-east-1')
    response = client.create_launch_configuration(
        LaunchConfigurationName=lc_name,
        ImageId=image_id,
     KeyName=ssh_key,
     SecurityGroups=[
         security,
     ],
#    InstanceId='string',
     InstanceType=instance_type,
     BlockDeviceMappings=[
         {
             'DeviceName': "/dev/xvda1",
             'Ebs': {
                 'VolumeSize': 15,
                 'DeleteOnTermination': True,
                 'Encrypted': False
             }
         },
         {
             'DeviceName': "/dev/xvdb",
             'Ebs': {
                 'VolumeSize': 8,
                 'DeleteOnTermination': True,
                 'Encrypted': False
             }
         },
     ],
     )
    return response


#img_id = {'ResponseMetadata': {'RetryAttempts': 0, 'HTTPStatusCode': 200, 'RequestId': '6db8c9a5-c602-480e-ba40-88994d55b2a1', 'HTTPHeaders': {'transfer-encoding': 'chunked', 'vary': 'Accept-Encoding', 'server': 'AmazonEC2', 'content-type': 'text/xml;charset=UTF-8', 'date': 'Wed, 12 Oct 2016 09:12:02 GMT'}}, u'ImageId': 'ami-23105a34'}
img_id = create_img(image_id, desc)
print img_id['ImageId']

#lc = {'ResponseMetadata': {'RetryAttempts': 0, 'HTTPStatusCode': 200, 'RequestId': 'ccff07a9-905e-11e6-8698-91b97012340f', 'HTTPHeaders': {'x-amzn-requestid': 'ccff07a9-905e-11e6-8698-91b97012340f', 'date': 'Wed, 12 Oct 2016 09:32:31 GMT', 'content-length': '237', 'content-type': 'text/xml'}}}
lc = create_lc(desc, img_id['ImageId'], 'api-dev-east', 'openapi-development', 'c3.xlarge')
