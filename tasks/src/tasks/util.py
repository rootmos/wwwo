import logging
import os
import shutil
import subprocess
import sys
import tempfile

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

def find_editor():
    e = env("EDITOR")
    if e is not None:
        return e

    e = os.environ.get("EDITOR")
    if e is not None:
        return e

    for e in ["nvim", "vim", "vi", "emacs"]:
        e = shutil.which(e)
        if e is not None:
            return e

    raise RuntimeError("unable to find an editor")

def run_with_tty(*cmdline, check=None):
    if check is None:
        check = True
    logger.debug(f"running with tty: {cmdline}")
    with open("/dev/tty", "rb") as i, open("/dev/tty", "wb") as o:
        p = subprocess.run(cmdline, check=check, stdin=i, stdout=o)
    return p.returncode == 0

def edit(x, editor=None, basename="edit"):
    editor = editor or find_editor()
    if not isinstance(x, dict):
        return run_with_tty(editor, x)

    import json
    fmt = {
        "dump": lambda x, f: json.dump(x, f, indent=2),
        "load": lambda f: json.load(f),
        "suffix": "json",
    }

    with tempfile.TemporaryDirectory() as tmp:
        fn = os.path.join(tmp, f"{basename}.{fmt['suffix']}")
        with open(fn, "x") as f:
            fmt["dump"](x, f)

        if run_with_tty(editor, fn):
            with open(fn, "r") as f:
                return fmt["load"](f)
