import argparse

from . import package_name, package_version
from . import util
from .util import env

import logging
logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(
            description="Meta information gatherer",
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("-v", "--version", action="version", version=f"%(prog)s {package_version}")

    parser.add_argument("--log", default=env("LOG_LEVEL", "WARN"), help="set log level")
    parser.add_argument("--log-file", metavar="FILE", default=env("LOG_FILE"), help="redirect stdout and stderr to FILE")

    return parser.parse_args()

def main():
    args = parse_args()
    if args.log_file is not None:
        sys.stderr = sys.stdout = open(args.log_file, "a")
    util.setup_logger(args.log)
    logger.debug(f"args: {args}")
