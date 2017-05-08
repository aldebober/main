#!/usr/bin/env python

import boto3
from subprocess import call
import sys

iops = 200
vol_id = [ ]    #Add vol_id in array
action = None

if(len(sys.argv) > 1):
    action = sys.argv[1]
elif((action is None) or (action != 'increase') or (action != 'decrease')):
    print "Use argument increase|decrease"
    sys.exit()
else:
    print "Use argument increase|decrease"
    sys.exit()



def check_status(vol_id):
    call("aws ec2 describe-volumes-modifications --volume-id %s" %(' '.join(vol_id)), shell=True )


def increase_iops(vol_id):
    if(vol['VolumeType'] != 'io1'):
        print "Increasing in progress for %s" %(vol['VolumeId'])
        call("aws ec2 modify-volume --volume-id %s --volume-type io1 --iops %d" %(vol['VolumeId'], iops), shell=True, )
    else:
        print "%s is already increased" % (vol['VolumeId'])
        print "Skip %s" %(vol['VolumeId'])


def decrease_iops(vol_id):
    if(vol['VolumeType'] != 'gp2'):
        print "Decreasing in progress for %s" %(vol['VolumeId'])
        call("aws ec2 modify-volume --volume-id %s --volume-type gp2" %(vol['VolumeId']), shell=True )
    else:
        print "%s is already decreased" % (vol['VolumeId'])
        print "Skip %s" %(vol['VolumeId'])



ec2 = boto3.resource('ec2')
client = boto3.client('ec2')
response = client.describe_volumes(
    VolumeIds = vol_id
    )

for vol in response['Volumes']:
    print vol['VolumeType'], vol['Iops']
    if(action == 'increase'):
        increase_iops(vol_id)
    elif(action == 'decrease'):
        decrease_iops(vol_id)

check_status(vol_id)    #Check proccesses
