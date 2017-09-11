#!/usr/bin/env python
import boto3
import json

client = boto3.client('ecs')


def json_print(data, indent=4):
    # After we get our output, we can format it to be more readable
    # by using this function.
    if type(data) == dict:
        print json.dumps(data, indent=indent, sort_keys=True)
    else:
        print data


def get_instance_ip(instance_id):
    name = None
    client = boto3.client('ec2')
    instances = [ _ for _ in client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'] ]
    interfaces = [ _ for _ in instances[0]['NetworkInterfaces'] ]
    private_ip = [ i['PrivateIpAddress'] for i in interfaces ]
 #   public_ip = [ i['Association']['PublicIp'] for i in interfaces ]
    if len(instances) > 0 and 'Tags' in instances[0]:
        tmp = [ _['Value'] for _ in instances[0]['Tags'] if _['Key'] == 'Name']
        if len(tmp) > 0:
            name = tmp[0]
    return private_ip, name


def get_cluster_tasks(cluster_desc):
#    cluster_desc = 'bws-ops-UtilTasks-1GLIWHA9ACVTJ-TurnCluster-32CJMQN5QS1B'
    taskArns = client.list_tasks(cluster=cluster_desc)['taskArns']
    if not taskArns:
        return None
    cluster_instance = {}
    tasks = client.describe_tasks(
        cluster=cluster_desc,
        tasks=taskArns
    )
    for task in tasks['tasks']:
        taskdef_arn = task['taskDefinitionArn']
        cluster_tasks = []
        info = {}
        #taskdef = client.describe_task_definition(taskDefinition=tasks['tasks'][0]['taskDefinitionArn'])
        taskdef = client.describe_task_definition(taskDefinition=taskdef_arn)   #Getting info about Task Definition
        container = client.describe_container_instances(        #Getting info about instance id, cpu, mem and ports
            cluster=cluster_desc,
            containerInstances=[
                task['containerInstanceArn'],
            ]
        )
        instance_id = container['containerInstances'][0]['ec2InstanceId']
        reg_ports = container['containerInstances'][0]['registeredResources'][2]['stringSetValue']
        reg_cpu = container['containerInstances'][0]['registeredResources'][0]['integerValue']
        reg_memory = container['containerInstances'][0]['registeredResources'][1]['integerValue']
        remain_cpu = container['containerInstances'][0]['remainingResources'][0]['integerValue']
        remain_memory = container['containerInstances'][0]['remainingResources'][1]['integerValue']
        for i in task['containers']:
            protocol = None
            hostPort = None
            if ('networkBindings' in i and [x for x in i['networkBindings'] if x is not None]):
#[{u'protocol': u'udp', u'bindIP': u'0.0.0.0', u'containerPort': 514, u'hostPort': 514}]
                protocol = [x['protocol'] for x in i['networkBindings']]
                hostPort = [x['hostPort'] for x in i['networkBindings']]
            info = {
                'name' : i['name'],
                'status' : i['lastStatus'],
                'protocol' : protocol,
                'hostPort' : hostPort,
                'reg_ports' : reg_ports,
                'reg_cpu' : reg_cpu,
                'reg_memory' : reg_memory,
                'remain_cpu' : remain_cpu,
                'remain_memory' : remain_memory,
                'task_id' : task['taskArn'].split(':')[5],
                'taskdef' : taskdef['taskDefinition']['containerDefinitions']
            }
            cluster_tasks.append(info)
        if(instance_id in cluster_instance):
            cluster_instance[str(instance_id)] += cluster_tasks
        else:
            cluster_instance[str(instance_id)] = cluster_tasks
    return cluster_instance


def get_cluster():
    response = client.list_clusters()
    clusters_arn = [ _.split(':')[5].split('/')[1] for _ in response['clusterArns']]
    return clusters_arn



#print "cluster;instnce_ip;instance_name;task_name;task_status;CPU(task_definition/register/remain);MEM(task_definition/register/remain);Port/Protocol;Container_image;S3_bucket;Logging_attr"
for cluster in get_cluster():
    instance = get_cluster_tasks(cluster)
    if not instance:
        continue
    print "CLUSTER: %s" % (cluster)
    for i, k in instance.items():
        instance_ip,instance_name = get_instance_ip(i)
        print "\n|--\tInstance: %s (%s)" % (instance_ip[0], instance_name)
        for task in k:
            port = []
            cpu = str(task['taskdef'][0]['cpu']) + '/' + str(task['reg_cpu']) + '/' + str(task['remain_cpu'])
            mem = str(task['taskdef'][0]['memory']) + '/' + str(task['reg_memory']) + '/' + str(task['remain_memory'])
            image = task['taskdef'][0]['image']
            if (task['hostPort'] is not None and len(task['hostPort']) > 0):
                for i in range(len(task['hostPort'])):
                    port.append(str(task['hostPort'][i]) + '(' + task['protocol'][i] + ')')
                port_str = ','.join(port)
            else:
                port_str = str(task['hostPort']) + '(' + str(task['protocol']) + ')'
            bucket = [ _['value'] for _ in task['taskdef'][0]['environment'] if _['name'] == 'S3_BUCKET_NAME']
            if bucket:
                bucket_name = bucket[0]
            else: bucket_name = None
            if 'logConfiguration' in task['taskdef'][0]:
                logConfiguration = task['taskdef'][0]['logConfiguration']['options']['tag'] + ':' + task['taskdef'][0]['logConfiguration']['options']['syslog-address']
            else:
                logConfiguration = None
            #print "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s" % (cluster, instance_ip[0], instance_name, task['name'], task['status'], cpu, mem, port_str, image, bucket_name, logConfiguration)
            print "|----\t\tTask: %s %s\tCPU(%s) MEM(%s) Port:%s Image%s" % (task['name'], task['status'], cpu, mem, port_str, image)
            print "\t\t\tParams: %s\t%s" % (bucket_name, logConfiguration)
            #print cluster, instance_ip[0], instance_name, task['name'], task['status'], cpu, mem, port_str, image, bucket_name, logConfiguration
    print "\n\n"

