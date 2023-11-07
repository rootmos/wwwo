import json
import os
import subprocess
import tempfile

from .util import env

import logging
logger = logging.getLogger(__name__)

def main(event, context):
    logger.info(f"event: {event}")

    workdir = tempfile.TemporaryDirectory(prefix="wwwo-")

    with open(os.path.join(workdir.name, ".invoke.json"), "w") as f:
        json.dump(event, f)

    exe = os.path.abspath("generate")
    args = [ "generate", "-w", workdir.name, "-J16" ]

    if env("TARGET"):
        args += [ "-u", env("TARGET") ]

        if env("BASE_URL"):
            args += [ "-p", env("BASE_URL") ]

    env_ext = { **os.environ,
        "AWS_REQUEST_ID": context.aws_request_id,
        "AWS_LAMBDA_FUNCTION_ARN": context.invoked_function_arn,
    }

    logger.debug(f"args: {args}")
    logger.debug(f"env: {env_ext}")
    subprocess.run(args, executable=exe, check=True, env=env_ext)
    logger.info(f"bye")
