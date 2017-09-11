#!/usr/bin/env python
# Search and output result from ElasticSearch
# Replace date_min, date_max with needed timestamp and match in body

# Requirements:
# pip install elasticsearch

import json
import elasticsearch

date_min = "2017-05-17T17:00:00.000Z"  # or now-1d
date_max = "2017-05-17T18:00:00.000Z"  # or now

body = {
    "query": {
        "bool": {
            "must": [

                {"match": {"program": "bws"}
                 },
                {
                    "range": {
                        "@timestamp": {
                            "gte": date_min,
                            "lte": date_max
                        }
                    }
                }
            ]
        }
    }
}

es = elasticsearch.Elasticsearch()
matches = es.search(index='logstash-*', size=1, body=body)
hits = matches['hits']['hits']
total = matches['hits']["total"]
print total
if not hits:
    print 'No matches found'
else:
    print json.dumps(matches, indent=4)
