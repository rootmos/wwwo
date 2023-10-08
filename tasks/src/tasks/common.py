import sys

from contextlib import contextmanager

import boto3

def fetch_secret(arn):
    sm = boto3.client(service_name="secretsmanager", region_name=arn.split(":")[3])
    return sm.get_secret_value(SecretId=arn)["SecretString"]

@contextmanager
def output(fn, mode="w"):
    if fn is None:
        if "b" in mode:
            yield sys.stdout.buffer
        else:
            yield sys.stdout
    else:
        f = open(fn, mode)
        try:
            yield f
        finally:
            f.close()
