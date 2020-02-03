#!/usr/bin/python
"""
Parsing wercker runs:
[
  {
    "id": "5e14bfc47b63df001ac522d3",
    "url": "https://app.wercker.com/api/v3/runs/5e14bfc47b63df001ac522d3",
    "branch": "develop",
    "tag": "",
    "commitHash": "6424d5a9aca4b0428acf5a9134c78838c1dc67c3",
    "createdAt": "2020-01-07T17:28:36.817Z",
    "finishedAt": "2020-01-07T17:36:37.147Z",
    "message": "Merge pull request #935 from arcanebet/BJ-163-favicon-fix-nested-urls\n\n[BJ-163]-favicon-fixed",
    "progress": 100,
    "result": "passed",
    "startedAt": "2020-01-07T17:29:09.537Z",
    "status": "finished",
    "user": {
      "userId": "5df35c7d0ad4cb0700aec144",
      "meta": {
        "username": "berrossdolmat",
        "type": ""
      },
      "avatar": {
        "gravatar": "e2f5a9cbc37c92ed3fca75ca226c327a"
      },
      "name": "berrossdolmat",
      "type": "wercker"
    },
    "pipeline": {
      "id": "5b361aa40c158e0100554236",
      "url": "https://app.wercker.com/api/v3/pipelines/5b361aa40c158e0100554236",
      "createdAt": "2018-06-29T11:40:20.776Z",
      "name": "store-staging",
      "permissions": "read",
      "pipelineName": "store",
      "setScmProviderStatus": false,
      "manualApproval": false,
      "type": "pipeline"
    }
  }
]
"""
import requests
from termcolor import colored

auth_token = '71dcfba6ccab45fbffc3650768ac9c5ef364f5f465209706c2ef6895b996744a'
bearer_token = 'Bearer ' +  auth_token
header = {'Authorization': bearer_token}
url = 'https://app.wercker.com/api/v3/runs'
frontend_id = '5b2a23ff4f14b001009ff2dc'
backend_id = '5b1f76c3bdf8750100221315'


def get_runs(app_id):
    response = requests.get(
        url,
        params=[('applicationId', app_id),
                ('limit', 6)],
        headers=header
    )

    return response


def print_runs(app_id):
    response = get_runs(app_id)
    for run in response.json():
        if (run["result"] == 'failed'):
            print '\x1b[1;32;40m' + run["result"] + '\x1b[0m' +\
                '\t' + run["user"]["meta"]["username"] + '\t' +\
                run["message"].split("\n")[0]
        else:
            print '\x1b[6;30;42m' + run["branch"] + '\x1b[0m' + '\t' +\
                run["pipeline"]["pipelineName"] + '\t' +\
                run["message"].split("\n")[0]


print_runs(frontend_id)
print_runs(backend_id)
