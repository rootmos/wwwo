import subprocess
import tempfile
import os

from .util import env

import logging
logger = logging.getLogger(__name__)

def main(event, context):
    logger.info(f"event: {event}")

    workdir = tempfile.TemporaryDirectory(prefix="wwwo-")

    exe = os.path.abspath("generate")
    args = [ "generate", "-w", workdir.name, "-J16" ]

    if env("TARGET"):
        args += [ "-u", env("TARGET") ]

        if env("BASE_URL"):
            args += [ "-p", env("BASE_URL") ]

    logger.debug(f"args: {args}")
    subprocess.run(args, executable=exe, check=True)
