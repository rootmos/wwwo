#!/usr/bin/env python3

import boto3
import json
from concurrent.futures import ThreadPoolExecutor

session = boto3.Session(profile_name="do")
s3 = session.resource("s3", endpoint_url="https://ams3.digitaloceanspaces.com")

pool = ThreadPoolExecutor(8)

bucket = s3.Bucket("rootmos-sounds")
os = filter(lambda o: o.key.endswith(".json") and "/" not in o.key, bucket.objects.all())
ss = pool.map(lambda o: json.loads(o.get()["Body"].read()), os)
print(json.dumps(list(ss), separators=(',', ':')))
