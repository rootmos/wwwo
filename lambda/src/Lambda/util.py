import logging
import os
import sys

from . import package_name, env_prefix

import logging
logger = logging.getLogger(__name__)

def env_name(var):
    return env_prefix + var

def env(var, default=None):
    return os.environ.get(env_name(var), default)
