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

    logger.debug(f"args: {args}")
    subprocess.run(args, executable=exe, check=True)
    logger.info(f"bye")
