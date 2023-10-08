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
        if event.get("dry_run"):
            args += [ "-n" ]

    logger.debug(f"args: {args}")
    subprocess.run(args, executable=exe, check=True)
