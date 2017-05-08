#!/usr/bin/env python
import boto3
import sys
import re

names = {
    'us-east-1':'nvirginia',
    'us-east-2':'ohio',
    'us-west-1':'ncalifornia',
    'us-west-2':'oregon',
    'eu-west-1':'ireland',
    'eu-central-1':'frankfurt'
}
vpcs = {}
if len(sys.argv) < 2:
    sys.exit('Usage: %s region_name' % sys.argv[0])
region = sys.argv[1].strip()
bastion = re.compile('bastion', re.I)

def check_region(r):
    client = boto3.client('ec2')
    regions = [region['RegionName'] for region in client.describe_regions()['Regions']]
    if r in regions:
        return True
    else:
        sys.exit('Region must be from list: %s' % ', '.join(regions))


def get_instance_ip(instance_id):
    #client = boto3.client('ec2', region_name=region)
    instances = [ _ for _ in client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'] ]
    for i in instances[0]['NetworkInterfaces']:
        private_ip = i['PrivateIpAddress']
        if 'Association' in i:
            public_ip = i['Association']['PublicIp']
        else:
            public_ip = None
    name = [ _['Value'] for _ in instances[0]['Tags'] if _['Key'] == 'Name'][0]
    keyname = instances[0]['KeyName']
    return private_ip, name, public_ip, keyname


def get_instances(subnet):
    #instances = {}
    name = None
    response = client.describe_instances(Filters=[ { 'Name': 'network-interface.subnet-id', 'Values': [subnet] } ] )
  #  if 'Reservations' in response and len(response['Reservations']) > 0:
    if 'Reservations' in response:
        if len(response['Reservations']) > 0:
            instances_id = [ i['InstanceId'] for i in response['Reservations'][0]['Instances']]
            return instances_id


def get_vpc_info(vpcid):
    vpc_name = None
    response = client.describe_vpcs(
        VpcIds=[
            vpcid
        ]
    )
    subnets = client.describe_subnets(Filters=[ { 'Name': 'vpc-id', 'Values': [vpcid] } ])
    subnets_id = [ x['SubnetId'] for x in subnets['Subnets'] ]
    vpc_cidr = response['Vpcs'][0]['CidrBlock']
    if 'Tags' in response['Vpcs'][0]:
        name = [tag["Value"] for tag in response['Vpcs'][0]['Tags'] if tag["Key"] == "Name"]
        if name:
            vpc_name = name[0]
    return vpc_name, vpc_cidr, subnets_id


def get_route_list():
    #subnets = []
    name = None
    response = client.describe_route_tables()
    for route_table in response["RouteTables"]:
        routes = []
        tag_name = [tag["Value"] for tag in route_table["Tags"] if tag["Key"] == "Name"]
        vpc_id = route_table["VpcId"]
        if len(tag_name) > 0:
            name = tag_name[0]
        subnets = [ x['SubnetId'] for x in [ subnet for subnet in route_table["Associations"] if "Associations" in route_table] if 'SubnetId' in x]
        info = {
            "name" : name,
            "subnets" : subnets,
            "vpcid" : route_table["VpcId"],
            "route_tableid" : route_table["RouteTableId"],
            "route_table" : route_table["Routes"]
        }
        routes.append(info)
        if vpc_id in vpcs:
            vpcs[vpc_id] += routes
        else:
            vpcs[vpc_id] = routes

    return vpcs


def write_host(fd, name, ip, key, user):
    print "Host %s" %name
    print "\thostname\t%s" % ip
    print "\tUser\t%s" % user
    print "\tIdentityFile\t~/.ssh/%s" % key
    print "\tProxyCommand\tssh proxy_%s nc  %%h %%p\n" % names[region]


def write_proxy(fd, ip, key, user):
    print "Host proxy_%s" % names[region]
    print "\thostname\t%s" % ip
    print "\tUser\t%s" % user
    print "\tIdentityFile\t~/.ssh/%s\n" % key


check_region(region)
client = boto3.client('ec2', region_name=region)

routes = get_route_list()
for vpc,routes in routes.items():
    vpc_name, vpc_cidr, all_subnets = get_vpc_info(vpc)
    explicit_subnet = []
    implicit_subnet = []
    print "VPC id: %s, name: %s, CIDR: %s" % (vpc, vpc_name, vpc_cidr)
    for route in routes:
        subnets = route["subnets"]
        if len(subnets) > 0:
            for subnet in subnets:
                if not subnet in explicit_subnet:
                    explicit_subnet.append(subnet)
                instances_id = get_instances(subnet)
                if instances_id:
                    for i in instances_id:
                        ip, name, public_ip, key = get_instance_ip(i)
                        if name and bastion.search(name):
                            write_proxy(i, public_ip, key, 'ec2-user')
                        else:
                            write_host(i, name, ip, key, 'ec2-user')

    implicit_subnet = list(set(all_subnets).symmetric_difference(set(explicit_subnet)))
    if len(implicit_subnet) > 0:
        for subnet in implicit_subnet:
                instances_id = get_instances(subnet)
                if instances_id:
                    for i in instances_id:
                        ip, name, public_ip, key = get_instance_ip(i)
                        write_host(i, name, ip, key, 'ec2-user')
    print "-------------------------------------\n\n"
