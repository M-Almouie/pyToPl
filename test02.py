#!/usr/bin/python3

# written by andrewt@cse.unsw.edu.au as a COMP2041 lecture example
# Print line from stdin in reverse order

import sys


lines = []
dines = []
sines = []
for line in sys.stdin:
    lines.append(line)
lines = sorted(lines)
i = len(lines) - 1
while i >= 0:
    print("lines is %d" % i, end='    ')
    i = i - 1

