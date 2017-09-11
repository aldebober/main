#!/usr/bin/env python

from troposphere import FindInMap, GetAtt, Join
from troposphere import Parameter, Output, Ref, Select, Tags, Template
import troposphere.ec2 as ec2


template = Template()

keyname_param = template.add_parameter(Parameter(
    "KeyName",
    Description="Name of an existing EC2 KeyPair to enable SSH "
                "access to the instance",
    Type="String",
))

vpcid_param = template.add_parameter(Parameter(
    "VpcId",
    Description="VpcId of your existing Virtual Private Cloud (VPC)",
    Type="String",
))

subnetid_param = template.add_parameter(Parameter(
    "SubnetId",
    Description="SubnetId of an existing subnet (for the primary network) in "
                "your Virtual Private Cloud (VPC)" "access to the instance",
    Type="String",
))

sshlocation_param = template.add_parameter(Parameter(
    "SSHLocation",
    Description="The IP address range that can be used to SSH to the "
                "EC2 instances",
    Type="String",
    MinLength="9",
    MaxLength="18",
    Default="0.0.0.0/0",
    AllowedPattern="(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})"
                   "/(\\d{1,2})",
    ConstraintDescription="must be a valid IP CIDR range of the "
                          "form x.x.x.x/x."
))


template.add_mapping('RegionMap', {
    "us-east-1":      {"AMI": "ami-6d1c2007"},
    "us-east-2":      {"AMI": "ami-6a2d760f"},
    "us-west-2":      {"AMI": "ami-f173cc91"},
    "eu-central-1": {"AMI": "ami-9bf712f4"},
    "eu-west-1":      {"AMI": "ami-24506250"},
    "sa-east-1":      {"AMI": "ami-3e3be423"},
    "ap-southeast-1": {"AMI": "ami-74dda626"},
    "ap-northeast-1": {"AMI": "ami-dcfa4edd"}
})

template.add_mapping('BastionRegionMap', {
    "us-east-1":      {"AMI": "ami-60b6c60a"},
    "us-east-2":      {"AMI": "ami-58277d3d"},
    "us-west-2":      {"AMI": "ami-f0091d91"},
    "eu-west-1":      {"AMI": "ami-bff32ccc"},
    "eu-central-1": {"AMI": "ami-9bf712f4"},
    "ap-southeast-1": {"AMI": "ami-c9b572aa"},
    "ap-northeast-1": {"AMI": "ami-383c1956"}
})

bastion_sg = template.add_resource(ec2.SecurityGroup(
    "BastionSecurityGroup",
    VpcId=Ref(vpcid_param),
    GroupDescription="Enable SSH access via port 22",
    SecurityGroupIngress=[
        ec2.SecurityGroupRule(
            IpProtocol="tcp",
            FromPort="22",
            ToPort="22",
            CidrIp="0.0.0.0/0",
        ),
    ],
))

ssh_sg = template.add_resource(ec2.SecurityGroup(
    "SSHSecurityGroup",
    VpcId=Ref(vpcid_param),
    GroupDescription="Enable SSH access via port 22",
    SecurityGroupIngress=[
        ec2.SecurityGroupRule(
            IpProtocol="tcp",
            FromPort="22",
            ToPort="22",
            CidrIp=Ref(sshlocation_param),
        ),
    ],
))

instances = {
        "dmp-ch-1-nn01": [ "t2.xlarge", [None, None]],
        "dmp-cm-1-cmg02": [ "t2.large", [200, 1]],
        "dmp-ch-1-dn03": [ "t2.large", [200, 3]],
        "dmp-haproxy-1-01": [ "t2.small", [None, None]]
        }

eip1 = template.add_resource(ec2.EIP(
        "EIP1",
        Domain="vpc",
))

num = 0
for hostname,param in instances.iteritems():
    devices = []
    ebs_root = {"DeviceName": "/dev/xvda", "Ebs" : { "VolumeSize" : "100" }}
    devices.append(ebs_root)
    intance_type,disks = param
    if disks[0] is not None:
        letters = ["h", "g", "e"]
        for x in range(disks[1]):
            diskname = "/dev/sd" + letters[x]
            ebs_data = {"DeviceName": diskname, "Ebs" : { "VolumeSize" : disks[0] }}
            devices.append(ebs_data)
    num += 1
    ec2_instance = template.add_resource(ec2.Instance(
        "EC2Instance" + str(num),
        ImageId=FindInMap("RegionMap", Ref("AWS::Region"), "AMI"),
        InstanceType=intance_type,
        KeyName=Ref(keyname_param),
        Tags=Tags(Name=hostname,Project="dmp-ops"),
        BlockDeviceMappings = devices,
        SubnetId=Ref(subnetid_param),
        SecurityGroups=[Ref(ssh_sg)]
    ))

ec2_instance1 = template.add_resource(ec2.Instance(
    "BastionInstance",
    ImageId=FindInMap("BastionRegionMap", Ref("AWS::Region"), "AMI"),
    InstanceType="t2.small",
    KeyName=Ref(keyname_param),
    SecurityGroups=[Ref(bastion_sg)],
    SubnetId=Ref(subnetid_param),
    Tags=Tags(Name="bastion",Project="dmp-ops"),
))

eipassoc1 = template.add_resource(ec2.EIPAssociation(
        "EIPAssoc1",
        AllocationId=GetAtt("EIP1", "AllocationId"),
        InstanceId=Ref(ec2_instance1)
))

print(template.to_json())
