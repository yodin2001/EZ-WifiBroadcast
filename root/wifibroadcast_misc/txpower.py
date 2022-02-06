#!/usr/bin/python

import subprocess
import sys

subprocess.check_call(['/usr/local/bin/txpower_atheros',sys.argv[1]])