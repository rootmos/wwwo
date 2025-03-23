import argparse
import json
import os

import boto3
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

    parser.add_argument("--error-sns-topic-arn", metavar="TOPIC_ARN", default=env("ERROR_SNS_TOPIC_ARN"), help="publish errors to the SNS topic TOPIC_ARN")

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

def region_of_arn(arn):
    return arn.split(":")[3]

def publish(topic_arn, subject, payload):
    boto3.client("sns", region_name=region_of_arn(topic_arn)).publish(
        TopicArn = topic_arn,
        Subject = subject[:100],
        MessageStructure = "json",
        Message = json.dumps({
            "default": json.dumps(payload),
            "SMS": subject[:140],
            "EMAIL": json.dumps(payload, indent=4),
        }),
    )

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

        if args.error_sns_topic_arn:
            region = os.environ["AWS_REGION"]

            subject = f"{ctx.function_name} ({region}): {e}"

            log_stream_url = f"https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#logEventViewer:group={ctx.log_group_name};stream={ctx.log_stream_name}"

            payload = {
                "exception": repr(e),
                "event": event,
                "invocation": {
                    "function_arn": ctx.invoked_function_arn,
                    "aws_request_id": ctx.aws_request_id,
                    "log": {
                        "group": ctx.log_group_name,
                        "stream": ctx.log_stream_name,
                        "url": log_stream_url,
                    }
                }
            }

            publish(topic_arn=args.error_sns_topic_arn, subject=subject, payload=payload)

        raise
    finally:
        handler.flush()
