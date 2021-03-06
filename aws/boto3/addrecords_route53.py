#!/usr/bin/env python
import boto3

#Scripts search all instances in subnet and adds ips and names to domain zones: int.scdmp.net, scdmp.net, 1.0.10.in-addr.arpa.

#Requirments 
#python 2.x
#pip install boto3

client_r53 = boto3.client('route53')
client = boto3.client('ec2')

zoneid1A=''     #int.scdmp.net Hosted Zone ID
zoneid2A=''     #scdmp.net Hosted Zone ID
zoneidPTR=''    #1.0.10.in-addr.arpa. Hosted Zone ID
subnet='subnet-0714b04e'       #Subnet ID
domain1 = 'int.scdmp.net'
domain2 = 'scdmp.net'
domain_ptr = "1.0.10.in-addr.arpa."

def get_instance_ip(instance_id):
    client = boto3.client('ec2')
    instances = [ _ for _ in client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'] ]
    interfaces = [ _ for _ in instances[0]['NetworkInterfaces'] ]
    private_ip = [ i['PrivateIpAddress'] for i in interfaces ]
 #   public_ip = [ i['Association']['PublicIp'] for i in interfaces ]
    name = [ _['Value'] for _ in instances[0]['Tags'] if _['Key'] == 'Name'][0]
    return private_ip, name


def get_instances(subnet):
    name = None
    response = client.describe_instances(Filters=[ { 'Name': 'network-interface.subnet-id', 'Values': [subnet] } ] )
    if 'Reservations' in response:
        if len(response['Reservations']) > 0:
            instances_id = [ i['Instances'][0]['InstanceId'] for i in response['Reservations'] ]
            return instances_id


def update_recordPTR(zoneid, domain_ptr, domain, hostname, ip):
    fqdn = hostname + '.' + domain
    ptr_name = str(ip.split('.')[3]) + '.' + domain_ptr
    try:
        response = client_r53.change_resource_record_sets(
            HostedZoneId=zoneid,
            ChangeBatch={
                'Changes': [ {
                    #'Action': 'UPSERT',
                    'Action': 'CREATE',
                    'ResourceRecordSet': {
                        'Name': ptr_name,
                        'Type': 'PTR',
                        'TTL': 900,
                        'ResourceRecords': [ { 'Value': fqdn }],
                },},]
            } )
    except:
        print "PTR record already exist"
    return response


def update_recordA(zoneid, domain, hostname, value):
    a_name = hostname + '.' + domain
    try:
        response = client_r53.change_resource_record_sets(
            HostedZoneId=zoneid,
            ChangeBatch={
                'Changes': [ {
                    'Action': 'CREATE',
                    'ResourceRecordSet': {
                        'Name': a_name,
                        'Type': 'A',
                        'TTL': 900,
                        'ResourceRecords': [ { 'Value': value } ],
                    },},]
            } )
    except:
        print "A Record already exist"
    return response


for instance_id in get_instances(subnet):
    private_ip,hostname = get_instance_ip(instance_id)
    print private_ip[0], hostname
    update_recordA(zoneid1A, domain1, hostname, private_ip[0])
    update_recordA(zoneid2A, domain2, hostname, private_ip[0])
    update_recordPTR(zoneidPTR, domain_ptr, domain, hostname, private_ip[0])
