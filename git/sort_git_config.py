#!/usr/bin/env python3
import argparse
import re

parser = argparse.ArgumentParser(description="Sort git config by section")
parser.add_argument("config", type=argparse.FileType("r+"))
args = parser.parse_args()
config_file = args.config

section_expression = re.compile(r"^\[.*\]$")

sections = {}
current_section = None
for line in config_file.readlines():
    if section_expression.search(line):
        sections[line] = []
        current_section = line
        continue

    sections[current_section].append(line)

config_file.seek(0)
for section in sorted(sections.keys()):
    config_file.write(section)
    config_file.writelines(sections[section])
