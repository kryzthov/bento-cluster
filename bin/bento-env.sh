#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# -*- mode: shell -*-

# (c) Copyright 2014 WibiData, Inc.
#
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ------------------------------------------------------------------------------

# Canonicalize a path into an absolute, symlink free path.
#
# Portable implementation of the GNU coreutils "readlink -f path".
# The '-f' option of readlink does not exist on MacOS, for instance.
#
# Args:
#   param $1: path to canonicalize.
# Stdout:
#   Prints the canonicalized path on stdout.
function resolve_symlink() {
  local target_file=$1

  if [[ -z "${target_file}" ]]; then
    echo ""
    return 0
  fi

  cd "$(dirname "${target_file}")"
  target_file=$(basename "${target_file}")

  # Iterate down a (possible) chain of symlinks
  local count=0
  while [[ -L "${target_file}" ]]; do
    if [[ "${count}" -gt 1000 ]]; then
      # Just stop here, we've hit 1,000 recursive symlinks. (cycle?)
      break
    fi

    target_file=$(readlink "${target_file}")
    cd $(dirname "${target_file}")
    target_file=$(basename "${target_file}")
    count=$(( ${count} + 1 ))
  done

  # Compute the canonicalized name by finding the physical path
  # for the directory we're in and appending the target file.
  local phys_dir=$(pwd -P)
  echo "${phys_dir}/${target_file}"
}

# ------------------------------------------------------------------------------

bento_env_path="${BASH_SOURCE:-$0}"
bento_env_path=$(resolve_symlink "${bento_env_path}")

BENTO_CLUSTER_HOME=$(dirname "$(dirname "${bento_env_path}")")
BENTO_CLUSTER_HOME=$(cd "${BENTO_CLUSTER_HOME}"; pwd -P)

HADOOP_CONF_DIR="${BENTO_CLUSTER_HOME}/client-conf/hadoop"
HBASE_CONF_DIR="${BENTO_CLUSTER_HOME}/client-conf/hbase"

export BENTO_CLUSTER_HOME
export HADOOP_CONF_DIR
export HBASE_CONF_DIR

# Linux environments obey the HOSTALIASES environment variable:
if [[ "$(uname)" == "Linux" ]]; then
  if [[ -z "$HOSTALIASES" ]]; then
    echo "WARNING: The HOSTALIASES environment variable is not set." 1>&2
    echo "WARNING: This may prevent applications from resolving the Bento host name." 1>&2
    echo "WARNING: Please update your bash configuration and add: " 1>&2
    echo "WARNING:     export HOSTALIASES=${HOME}/.hosts" 1>&2

    # Make sure the file exists
    touch "${HOME}/.hosts"
    export HOSTALIASES="${HOME}/.hosts"
  fi
fi

export PATH="${BENTO_CLUSTER_HOME}/bin:${PATH}"
