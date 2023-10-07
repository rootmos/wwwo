import argparse
import os

import awslambdaric.bootstrap

from . import package_name, package_version
from .util import env

import logging
logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(
            description="AWS Lambda runner",
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("-v", "--version", action="version", version=f"%(prog)s {package_version}")

    parser.add_argument("--log", default=env("LOG_LEVEL", "WARN"), help="set log level")
    parser.add_argument("--log-file", metavar="FILE", default=env("LOG_FILE"), help="redirect stdout and stderr to FILE")

    parser.add_argument("-C", "--directory", metavar="DIR", help="change to directory DIR before executing handler")

    return parser.parse_args()

args = None
def run():
    global args
    args = parse_args()
    awslambdaric.bootstrap.run(os.getcwd(), f"{__name__}.entrypoint", os.environ["AWS_LAMBDA_RUNTIME_API"])

def remove_default_logging():
    l = logging.getLogger()
    while l.hasHandlers():
        l.removeHandler(l.handlers[0])

def setup_logger(level, ctx):
    level = level.upper()
    l = logging.getLogger(package_name)
    l.setLevel(level)

    ch = logging.StreamHandler()
    ch.setLevel(level)

    f = logging.Formatter(fmt=f"%(asctime)s:{ctx.aws_request_id}:%(name)s:%(levelname)s %(message)s", datefmt="%Y-%m-%dT%H:%M:%S%z")
    ch.setFormatter(f)

    l.addHandler(ch)

    return l, ch

def entrypoint(event, ctx):
    assert(args is not None)
    remove_default_logging()
    logger, handler = setup_logger(args.log, ctx)

    try:
        if args.directory is not None:
            logger.debug(f"changing directory: {args.directory}")
            os.chdir(args.directory)
        else:
            logger.debug(f"working directory: {os.getcwd()}")
        from . import main
        return main.main(event, ctx)
    except Exception as e:
        logger.error(e)
        raise
    finally:
        handler.flush()
