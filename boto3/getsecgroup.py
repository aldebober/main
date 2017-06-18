#!/usr/bin/env python

import boto3

ec2 = boto3.resource('ec2') #

sgs = list(ec2.security_groups.all())
insts = list(ec2.instances.all())

all_sgs = set([sg.group_name for sg in sgs])
all_inst_sgs = set([sg['GroupName'] for inst in insts for sg in inst.security_groups])
unused = all_sgs - all_inst_sgs

client = boto3.client('ec2')
response = client.describe_security_groups()


print 'GroupID;GroupName;Protocol;Port;Cidr addresses;Paired Groups;State'
for group in response['SecurityGroups']:
    if len(group['IpPermissions']) > 0:
        for permission in group['IpPermissions']:
            cidr = []
            groupPaired = []
            state = 'active'
            if group['GroupName'] in unused:
                state = 'inactive'
            ipp = permission['IpProtocol']
            ipr = permission['IpRanges']
            for ip in ipr:
                cidr.append(ip['CidrIp'])
            uidgps = permission['UserIdGroupPairs']
            for grps in uidgps:
                groupPaired.append(grps['GroupId'])
            plis = permission['PrefixListIds']
            if 'ToPort' in permission.keys():
                print group['GroupId'] + ';' + group['GroupName'] + ';' + ipp + ';' + str(permission['ToPort']) + ';' + ','.join(cidr) + ';' + ','.join(groupPaired) + ';' + state
            else:
                print group['GroupId'] + ';' + group['GroupName'] + ';' + ipp + ';Null;' + ','.join(cidr) + ';' + ','.join(groupPaired) + ';' + state
