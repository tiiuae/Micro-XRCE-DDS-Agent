#!/usr/bin/python3

import sys, os
import pystache

agent_refs_path=""
if len(sys.argv) > 1:
  agent_refs_path=sys.argv[1]

env_keystore = os.environ.get("ROS_SECURITY_KEYSTORE")
env_enclave_override = os.environ.get("ROS_SECURITY_ENCLAVE_OVERRIDE")

if env_keystore is None:
  print("environment variable 'ROS_SECURITY_KEYSTORE' not set")
  sys.exit(0)

if env_enclave_override is None:
  print("ERROR: environment variable 'ROS_SECURITY_ENCLAVE_OVERRIDE' not found")
  sys.exit(-1)

# Remove backslash from beginning of override path to avoid os.path.join to
#  start over from the root
if env_enclave_override.startswith("/"):
  env_enclave_override = env_enclave_override[1:]

enclave_path = os.path.join(env_keystore, "enclaves", env_enclave_override)
key_path = os.path.join(enclave_path, "key.p11")

if not os.path.exists(key_path):
  print("ERROR: file '" + key_path + "' not found")
  sys.exit(-2)

key = ""
tmpl = ""

with open(key_path, "r") as f:
  key = f.read().rstrip()

agent_refs_must_file = os.path.join(agent_refs_path, "dds_security_part_mustache.xml")
with open(agent_refs_must_file, "r") as f:
  tmpl = f.read()

agent_refs_data = pystache.render(tmpl, {'enclave_path': enclave_path, 'key_p11': key })

# Remove original agent.refs
agent_refs_file = os.path.join(agent_refs_path, "dds_security_part.xml")
if os.path.exists(agent_refs_file):
  os.remove(agent_refs_file)

# Write new agent.refs with sros params
with open(agent_refs_file, 'w') as f:
  f.write(agent_refs_data)
