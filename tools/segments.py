#!/usr/bin/env python3

import platform
import os
import subprocess
import re
import sys
import shutil

if len(sys.argv) != 2:
    print(f"Usage {sys.argv[0]} <build-dir>")
    exit(1)

toolchain = ""

if platform.uname().system == "Linux":
    wonderful = "/opt/wonderful/toolchain/gcc-arm-none-eabi/bin"
    toolchain = f"{wonderful}/"

build_dir = sys.argv[1]
temp_dir = build_dir + "/extracted-segments"

if not os.path.isdir(build_dir):
    print("Could not find build directory")
    exit(1)

version = re.search("(..)_nds", build_dir).groups()[0]

nm = f"{toolchain}arm-none-eabi-nm"
objcopy = f"{toolchain}arm-none-eabi-objcopy"
elf = f"{build_dir}/sm64.{version}.arm9.elf"

(s, l) = subprocess.getstatusoutput(f"{nm} {elf}")

if s != 0:
    print("failed to run nm on the elf")
    exit(1)

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

os.mkdir(temp_dir)
os.mkdir(build_dir + "/nitro")

with open(build_dir + "/nitro/blob.bin", "wb") as out:
    for (seg, start) in starts.items():
        end = ends[seg]
        segsize = end - start
        #print(f"{seg} {start} {end} size: {segsize}")
        if seg == "goddard":
            continue

        fname = f"{temp_dir}/{seg}.bin"

        #os.remove(fname)
        (status, output) = subprocess.getstatusoutput(f"{objcopy} -O binary --only-section=.sm64.{seg} {elf} {fname}")
        if status != 0:
            print("objcopy fail")
            exit(1)

        content = open(fname, "rb").read()
        #print(len(content))

        out.seek(start)
        out.write(content)

shutil.rmtree(temp_dir)
