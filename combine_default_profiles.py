#!/usr/bin/python3

import sys, os
import shutil

agent_refs_path=""
if len(sys.argv) > 1:
  agent_refs_path=sys.argv[1]

dds_security_part_file = os.path.join(agent_refs_path, "dds_security_part.xml")
default_profiles_file = os.path.join(agent_refs_path, "default_profiles.xml")
agent_refs_tmp_file = os.path.join(agent_refs_path, "agent.refs.tmp")
agent_refs_file = os.path.join(agent_refs_path, "agent.refs")

def cleanup_temporary_files():
  # cleanup  
  if os.path.exists(agent_refs_tmp_file):
    os.remove(agent_refs_tmp_file)
  if os.path.exists(default_profiles_file):
    os.remove(default_profiles_file)
  if os.path.exists(dds_security_part_file):
    os.remove(dds_security_part_file)


if not os.path.exists(dds_security_part_file):
  print("No ROS2 security additions found for default profiles")
  cleanup_temporary_files()
  sys.exit(0)

sec_part_data = ""
with open(dds_security_part_file, "r") as f:
  sec_part_data = f.read()

### Combine security part to original profiles data
keep_config = True
with open(default_profiles_file, "r") as in_f:
  with open(agent_refs_tmp_file, "w") as out_f:
    for line in in_f.readlines():
      line_str = line.strip()
      # Remove data_reader and data_writer configs
      #  as they conflicts with xrce client side configs
      if line_str.startswith("<data_writer") or line_str.startswith("<data_reader"):
        keep_config = False

      if keep_config:
        out_f.write(line)
        if line_str.startswith("<rtps>"):
          out_f.write(sec_part_data)

      if line_str.startswith("</data_writer") or line_str.startswith("</data_reader"):
        keep_config = True

# Replace original agent.refs with generated one
if os.path.exists(agent_refs_tmp_file):
  if os.path.exists(agent_refs_file):
    os.remove(agent_refs_file)
  shutil.copyfile(agent_refs_tmp_file, agent_refs_file)

cleanup_temporary_files()
