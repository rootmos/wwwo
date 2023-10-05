import subprocess
import tempfile
import os

import logging
logger = logging.getLogger(__name__)

def main(event, context):
    logger.info(f"event: {event}")

    workdir = tempfile.TemporaryDirectory(prefix="wwwo-")
    exe = os.path.abspath("generate")
    logger.debug(f"executable: {exe}")
    args = [ "generate", "-w", workdir.name, "-J16" ]
    logger.debug(f"args: {args}")
    subprocess.run(args, executable=exe, check=True)
