#!/usr/bin/python
"""
Parsing wercker runs:
[
  {
    "id": "",
    "url": "https://app.wercker.com/api/v3/runs/..",
    "branch": "develop",
    "tag": "",
    "commitHash": "",
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
      "id": "",
      "url": "https://app.wercker.com/api/v3/pipelines/..",
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

auth_token = ''
bearer_token = 'Bearer ' +  auth_token
header = {'Authorization': bearer_token}
url = 'https://app.wercker.com/api/v3/runs'
frontend_id = ''
backend_id = ''


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
