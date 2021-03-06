#!/usr/bin/env python

import json
import os
import sys


# Called by entrypoint.sh, handles input parsing
# We would normally not want to have this hard coded, but rely on entrypoint.sh
# to ensure arguments are provided.

dockerfile = sys.argv[1]
output_format = sys.argv[2]
contact_name = sys.argv[3]
container_name = sys.argv[4]

output_format = output_format.lower()

# Import extract function
from extract import extract

# Don't define an output html, the user can pipe to one if desired
result = extract(dockerfile, contact_name, container_name, output_format == "html")
    
print(result)
