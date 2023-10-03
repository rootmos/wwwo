import logging
logger = logging.getLogger(__name__)

def main(event, context):
    logger.info(f"event: {event}")
    logger.info(f"context: {context}")

    return "Hello Lambda world!"
