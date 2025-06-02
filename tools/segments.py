#!/usr/bin/env python3

import platform
import os
import subprocess
import re

toolchain = ""

if platform.uname().system == "Linux":
    wonderful = "/opt/wonderful/toolchains/gcc-arm-none-eabi/bin"
    toolchain = f"{wonderful}/"

nm = f"{toolchain}arm-none-eabi-nm"
objcopy = f"{toolchain}arm-none-eabi-objcopy"
elf = "build/us_nds/sm64.us.arm9.elf"

l = subprocess.getoutput(f"{nm} {elf}")

starts = {}
ends = {}

for s in l.split("\n"):
    if not "SegmentRom" in s:
        continue
    
    match = re.search("([0-9a-fA-F]+) . _(.+)Segment", s)
    if not match:
        print("couldn't find addr")
        exit(1)

    addr = int(match.group(1), 16)
    name = match.group(2)

    if "Start" in s:
        starts[name] = addr
    elif "End" in s:
        ends[name] = addr
    else:
        print("not start/end")
        exit(1)

if starts.keys() != ends.keys():
    print("keys didn't match")
    exit(1)

os.mkdir("extracted-segments")

with open("out.bin", "wb") as out:
    for (seg, start) in starts.items():
        end = ends[seg]
        segsize = end - start
        print(f"{seg} {start} {end} size: {segsize}")
        if seg == "goddard":
            continue

        fname = f"extracted-segments/{seg}.bin"

        #os.remove(fname)
        (status, output) = subprocess.getstatusoutput(f"{objcopy} -O binary --only-section=.sm64.{seg} {elf} {fname}")
        if status != 0:
            print("objcopy fail")
            exit(1)

        content = open(fname, "rb").read()
        print(len(content))

        out.seek(start)
        out.write(content)
