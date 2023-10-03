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

def setup_logger(level):
    level = level.upper()
    l = logging.getLogger(package_name)
    l.setLevel(level)

    ch = logging.StreamHandler()
    ch.setLevel(level)

    f = logging.Formatter(fmt="%(asctime)s:%(name)s:%(levelname)s %(message)s", datefmt="%Y-%m-%dT%H:%M:%S%z")
    ch.setFormatter(f)

    l.addHandler(ch)

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)
