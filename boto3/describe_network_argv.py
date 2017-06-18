#!/usr/bin/env python
import boto3
import sys

vpcs = {}
if len(sys.argv) < 2:
    sys.exit('Usage: %s region_name' % sys.argv[0])
region = sys.argv[1].strip()

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
        if 'PrivateIpAddress' in i:
            private_ip = i['PrivateIpAddress']
        else:
            private_ip = None
        if 'Association' in i:
            public_ip = i['Association']['PublicIp']
        else:
            public_ip = None
    try:
        name = [ _['Value'] for _ in instances[0]['Tags'] if _['Key'] == 'Name'][0]
    except:
        name = None
    return private_ip, name, public_ip


def get_alone_instances():
    #instances = {}
    name = None
    instances_ids = []
    response = client.describe_instances()
    if 'Reservations' in response:
        if len(response['Reservations']) > 0:
            for Z in range(0, len(response['Reservations'])):
                instances_id = [ i['InstanceId'] for i in response['Reservations'][Z]['Instances']]
                instances_ids = instances_ids + instances_id
    return instances_ids


def get_instances(subnet):
    #instances = {}
    name = None
    instances_ids = []
    response = client.describe_instances(Filters=[ { 'Name': 'network-interface.subnet-id', 'Values': [subnet] } ] )
  #  if 'Reservations' in response and len(response['Reservations']) > 0:
    if 'Reservations' in response:
        if len(response['Reservations']) > 0:
            for Z in range(0, len(response['Reservations'])):
                instances_id = [ i['InstanceId'] for i in response['Reservations'][Z]['Instances']]
                instances_ids = instances_ids + instances_id
     #   return instances_ids
            #instances_id = [ i['InstanceId'] for i in response['Reservations'][0]['Instances']]
    return instances_ids


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


def AccepterVpcInfo(vpcid):
    response = client.describe_vpc_peering_connections(VpcPeeringConnectionIds=[vpcid])
    if response:
        vpc_id = [x['AccepterVpcInfo']['VpcId'] for x in response['VpcPeeringConnections'] ]
    return vpc_id


def nat_gateways_info(nat_id):
    public_ip = None
    private_ip = None
    response = client.describe_nat_gateways(NatGatewayIds=[ nat_id ])
    if response:
        public_ip = response['NatGateways'][0]['NatGatewayAddresses'][0]['PublicIp']
        private_ip = response['NatGateways'][0]['NatGatewayAddresses'][0]['PrivateIp']
    return private_ip, public_ip


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



check_region(region)
client = boto3.client('ec2', region_name=region)

routes = get_route_list()
for vpc,routes in routes.items():
    vpc_name, vpc_cidr, all_subnets = get_vpc_info(vpc)
    explicit_subnet = []
    implicit_subnet = []
    print "-------------------------------------\n\n"
    print "VPC id: %s, name: %s, CIDR: %s" % (vpc, vpc_name, vpc_cidr)
    for route in routes:
        print "|\n"
        print "|-Route name: %s, Route ID: %s" % (route["name"], route["route_tableid"])
        for table in route["route_table"]:
            target = None
            destination = None
            if 'Origin' in table and table['Origin'] == 'CreateRoute':
                if 'DestinationPrefixListId' in table:
                    target = table['GatewayId']
                    destination = table['DestinationPrefixListId']
                elif 'VpcPeeringConnectionId' in table:
                    vpcs_id = AccepterVpcInfo(table['VpcPeeringConnectionId'])
                    vpc_name, vpc_cidr, _ = get_vpc_info(vpcs_id[0])
                    target = table['VpcPeeringConnectionId'] + " <=> " + ' '.join(vpcs_id) + ' ' + vpc_name + '(' + vpc_cidr + ')'
                    destination = table['DestinationCidrBlock']
                elif 'NatGatewayId' in table:
                    private_ip, public_ip = nat_gateways_info(table['NatGatewayId'])
                    target = table['NatGatewayId'] + '\tIPs: ' + public_ip + '(' + private_ip + ')'
                    destination = table['DestinationCidrBlock']
                elif 'GatewayId' in table:
                    target = table['GatewayId']
                    destination = table['DestinationCidrBlock']
                else:
                    print table
            else:
                target = table['GatewayId']
                destination = table['DestinationCidrBlock']
            print "\t%s => %s"%(destination, target)
        subnets = route["subnets"]
        if len(subnets) > 0:
            for subnet in subnets:
                if not subnet in explicit_subnet:
                    explicit_subnet.append(subnet)
                print "|--\t\tSubnet: %s" %(subnet)
                instances_id = get_instances(subnet)
                if instances_id:
                    for i in instances_id:
                        ip, name, public_ip = get_instance_ip(i)
                        print "|----\t\t\tInstance: %s  %s NAME %s" %(i, ip, name)

    implicit_subnet = list(set(all_subnets).symmetric_difference(set(explicit_subnet)))
    if len(implicit_subnet) > 0:
        print "\nThere are some explicitly associated subnets: %s" % implicit_subnet
        for subnet in implicit_subnet:
                print "|--\t\tSubnet: %s" %(subnet)
                instances_id = get_instances(subnet)
                if instances_id:
                    for i in instances_id:
                        ip, name, public_ip = get_instance_ip(i)
                        print "|----\t\t\tInstance: %s  %s NAME %s" %(i, ip, name)
    print "-------------------------------------\n\n"
#    instances_id = get_alone_instances()
#    if instances_id:
#        for i in instances_id:
#            print get_instance_ip(i)
            #print "|----\t\t\tInstance: %s  %s NAME %s" %(i, ip, name)
#    print "-------------------------------------\n\n"

