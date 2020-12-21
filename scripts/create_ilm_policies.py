#!/usr/bin/env python

import yaml
import sys
import re
import json
import requests
import time


curator_file = sys.argv[1]
to_delete = {}
to_freeze = {}
prog = re.compile("-logs-[a-z-_\d]+|-switches-")

HOSTNAME="127.0.0.1"
PORT=9201


def make_list(value):
    return prog.findall(value)


def intersection(lst1, lst2):
    return list(set(lst1) & set(lst2))


def diff(lst1, lst2):
    return list(set(lst1) - set(lst2))


def format_list(lst):
    final_list = [re.sub('^-', '*-', i) for i in lst]
    return [re.sub('-$', '-*', i) for i in final_list]


def format_name(descr,pref):
        return descr.replace(" ", "_").lower() + pref


def es_request(method, uri, body = ''):
    url = "http://" + HOSTNAME + ":" + str(PORT) + '/' + uri
    headers={"Content-Type":"application/json"}
    if method in ['GET', 'PUT', 'DELETE']:
        if method == 'GET':
            httpresp = requests.get(url, headers=headers, verify=False)
        elif method == 'PUT':
            data=json.dumps(body)
            httpresp = requests.put(url, data, headers=headers)
        elif method == 'DELETE':
            httpresp = requests.delete(url, headers=headers, verify=False)
        else:
            return None

    return httpresp


def add_policy(name, body):
    path = '_ilm/policy/' + name
    policy = es_request('PUT', path, body)
    if(policy.status_code == 200):
        res = policy.json()['acknowledged']
    else:
        print policy.json()
    return res


def get_policy(name):
    path = '_ilm/policy/' + name
    policy = es_request('GET', path)
    return policy.json()


def add_template(name, body):
    path = '_template/' + name
    template = es_request('PUT', path, body)
    if(template.status_code == 200):
        res = template.json()['acknowledged']
    elif(template.status_code == 400):
        res = template.json()['error']['root_cause'][0]['reason']
    else:
        print template.json()
    return res


def get_template(name):
    path = '_template/' + name
    template = es_request('GET', path)
    return template.json()


def update_settings(name, patterns):
    res = {}
    for pattern in patterns:
        setting_path = pattern + '/_settings'
        setting_body = { "index": { "lifecycle": { "name": name }}}
        setting = es_request('PUT', setting_path, setting_body)
        if(setting.status_code == 200):
            r = setting.json()['acknowledged']
        else:
            r = 'NotApplied'
            print('\x1b[1;33;31mError: \x1b[0m{}'.format(str(setting.json()['error'])))
        res[pattern] = r
    return res


def test_ilm(ilm, failed):
    for policy in ilm:
        policy_check = get_policy(policy)
        if policy_check[policy]:
            print('\n\x1b[1;32;40mCreated policy:\x1b[0m {:<25} \x1b[1;33;40mwith actions: \x1b[0m{:^50}'.format(policy,str(policy_check[policy]['policy']['phases'])))
        else:
            print "\nError policy create: " + name
        template_check = get_template(policy)
        template_patterns = template_check[policy]['index_patterns']
        template_policy = template_check[policy]["settings"]["index"]["lifecycle"]["name"]
        if(template_policy == policy):
            print('\x1b[1;33;40mTemplate was created with lifecycle:\x1b[0m{:^50}'.format(template_policy))
        else:
            print policy + "has wrong lifecycle in template: " + template_policy
        print('\n\x1b[1;32;40mTemplate patterns:\t\x1b[0m{:>20}'.format(str(template_patterns)))
        common = intersection(template_patterns,ilm[policy])
        diff_t = diff(template_patterns,ilm[policy])
        print('\x1b[1;32;40mApplied to: \t\x1b[0m{:>20}'.format(str(common)))
        print('\x1b[1;32;40mLost: \t\x1b[0m{:>20}'.format(str(diff_t)))
        print('\nTotal: {}({}), Applied: {}, Lost: {}'.format(len(template_patterns),len(common)+len(diff_t),len(common),len(diff_t)))
    for policy in failed:
        print('\x1b[1;33;31mCoudn\'t attach policy \x1b[0m{} to indexes: {}'.format(policy, str(failed[policy])))



if __name__ == '__main__':

# Trying to parse curator yaml config
# Creating two lists to delete and freeze

    with open(curator_file, 'r') as stream:
        try:
            data = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    for num in data['actions']:
        action_type = data['actions'][num]['action']
        filters = data['actions'][num]['filters']
        if(action_type == 'delete_indices'):
            try:
                value = filters[0]['value']
            except:
                value = ''
                pass
            pattern_list = make_list(value)
            if len(pattern_list) > 0:
                to_delete[num] = pattern_list
        else:
            try:
                value = filters[0]['value']
            except:
                value = ''
                pass
            pattern_list = make_list(value)
            if len(pattern_list) > 0:
                to_freeze[num] = pattern_list

# Open wildcard queries

    body = { "persistent" : {"action" : { "destructive_requires_name": "false" }}}
    print es_request('PUT', '_cluster/settings', body)

# For each delete policy looking for entries in lists to freeze
# Getting intersection list to create policy with freeze and delete actions

    for i in to_delete:
        to_delete_days = data['actions'][i]['filters'][1]['unit_count']
        for j in to_freeze:
            ilm = {}
            failed = {}
            common_list = intersection(to_delete[i], to_freeze[j])
            if(common_list):
                to_freeze_days = data['actions'][j]['filters'][2]['unit_count']
                name = format_name(data['actions'][i]['description'],'_freeze_' + str(to_freeze_days))
                patterns = format_list(common_list)

                to_delete[i] = diff(to_delete[i], to_freeze[j])

                # Creating policy
                policy_body = { "policy": { "phases": { "cold": { "min_age": str(to_freeze_days) + "d", "actions": { "freeze": {} }}, "delete": { "min_age": str(to_delete_days) + "d", "actions": { "delete": {} }}}}}
                policy = add_policy(name, policy_body)
                print('\x1b[1;32;40mCreated ilm policy {} {:^30}\x1b[0m'.format(name, policy))

                # Creating template
                template_body = { "index_patterns": patterns, "settings": { "index.lifecycle.name": name, "index.lifecycle.parse_origination_date": 'true' }}
                template = add_template(name, template_body)
                print('\x1b[1;32;40mCreated template {} {:^30}\x1b[0m'.format(name, template))

                # Updating setting for existing indicies
                update_res = update_settings(name, patterns)
                for pattern in update_res:
                    if(update_res[pattern] == True):
                        if name in ilm:
                            ilm[name].append(pattern)
                        else:
                            ilm[name] = [pattern]
                    else:
                        if name in failed:
                            failed[name].append(pattern)
                        else:
                            failed[name] = [pattern]

                print '\nChecks'
                test_ilm(ilm, failed)
                time.sleep(10)      # If it's necessary

# Checking the rest of patterns for deleting wo freezing policy

    print "\nOnly for deleting:\n"
    for i in to_delete:
        ilm = {}
        failed = {}
        name = format_name(data['actions'][i]['description'],'')
        patterns = format_list(to_delete[i])
        age = data['actions'][i]['filters'][1]['unit_count']

        # Creating policy
        policy_body = { "policy": { "phases": { "delete": { "actions": { "delete": {}}, "min_age": str(age) + "d" }}}}
        policy = add_policy(name, policy_body)
        print('\x1b[1;32;40mCreated ilm policy {} {:^30}\x1b[0m'.format(name, policy))

        # Creating template
        template_body = { "index_patterns": patterns, "settings": { "index.lifecycle.name": name, "index.lifecycle.parse_origination_date": 'true' }}
        template = add_template(name, template_body)
        print('\x1b[1;32;40mCreated template {} {:^30}\x1b[0m'.format(name, template))

        # Updating setting for existing indicies
        update_res = update_settings(name, patterns)
        for pattern in update_res:
            if(update_res[pattern] == True):
                if name in ilm:
                    ilm[name].append(pattern)
                else:
                    ilm[name] = [pattern]
            else:
                if name in failed:
                    failed[name].append(pattern)
                else:
                    failed[name] = [pattern]

        print '\nChecks'
        test_ilm(ilm, failed)

# Close wildcard queries

    body = { "persistent" : {"action" : { "destructive_requires_name": "true" }}}
    print es_request('PUT', '_cluster/settings', body)
