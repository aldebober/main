#!/usr/bin/python
"""
Listing all services in cluster and describing status and image of tasks
"""

import boto3

cluster = 'arcanebet'
region = 'eu-west-1'
client = boto3.client('ecs', region)


def get_services(cluster):
    """
    Retuns list of service names
    """
    response = client.list_services(
        cluster=cluster,
        schedulingStrategy='REPLICA'
        )

    return [t.split("/")[1] for t in response['serviceArns']]


def get_dead_tasks(cluster):

    response = client.list_tasks(
        cluster=cluster,
        desiredStatus='STOPPED'
        )

    return [t.split("/")[1] for t in response['taskArns']]


def get_tasks(cluster, service_name):
    """
    Returns task ids
    """
    response = client.list_tasks(
        cluster=cluster,
        serviceName=service_name
        )

    return [t.split("/")[1] for t in response['taskArns']]


def get_task_statuses(service_name, cluster):
    """
    Retrieve task desciption from ECS API
    """
    task_ids = get_tasks(cluster, service_name)
    response = client.describe_tasks(
        tasks=task_ids,
        cluster=cluster
        )

    return response['tasks']


def get_fails(cluster):
    """
    Retrieve failed tasks logs
    """
    task_ids = get_dead_tasks(cluster)
    if (task_ids):
        response = client.describe_tasks(
            tasks=task_ids,
            cluster=cluster
            )
    else:
        return None

    return response['failures']


def main():
    services = get_services(cluster)
    for name in services:
        for task in get_task_statuses(name, cluster):
            for container in task['containers']:
                status = '\x1b[1;32;40m' + task['lastStatus'] +'\x1b[0m'
                name = container['name']
                image_tag = container.get('image', '').split(":")[1]
                date = '\x1b[1;33;42m' + task['createdAt'].strftime('%Y-%m-%d::%H-%M') +'\x1b[0m'
                print('{:<25}{:<30}{:^30}{:^50}'.format(name, status, image_tag, date))
    print get_fails(cluster)


if __name__ == '__main__':
    main()
