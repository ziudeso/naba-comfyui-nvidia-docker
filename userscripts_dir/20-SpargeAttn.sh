#!/bin/bash

## requires: 00-pip3dev.sh

# WiP: not building
exit 0


min_spas_sage_attn_version="0.1.9"

set -e

error_exit() {
  echo -n "!! ERROR: "
  echo $*
  echo "!! Exiting script (ID: $$)"
  exit 1
}

source /comfy/mnt/venv/bin/activate || error_exit "Failed to activate virtualenv"

# Adapted from https://github.com/eddiehavila/ComfyUI-Nvidia-Docker/blob/main/user_script.bash
# and https://github.com/yansigit/ComfyUI-Nvidia-Docker/blob/main/attn-build.bash
compile_flag=true
if pip3 show spas_sage_attn &>/dev/null; then
  # Extract the installed version of spas_sage_attn
  spas_sage_attn_version=$(pip3 show spas_sage_attn | grep '^Version:' | awk '{print $2}')
  echo "spas_sage_attn is installed with version $spas_sage_attn_version"

  # Use version sort to check if spas_sage_attn_version is below the minimal version
  # This command prints the lowest version of the two.
  # If the lowest isn't the minimal version, then spas_sage_attn_version is below the minimal version.
  if [ "$(printf '%s\n' "$spas_sage_attn_version" "$min_spas_sage_attn_version" | sort -V | head -n1)" != "$min_spas_sage_attn_version" ]; then
    echo "spas_sage_attn version $spas_sage_attn_version is below minimum version $min_spas_sage_attn_version, need to compile"
  else
    compile_flag=false
  fi
fi

if [ "A$compile_flag" = "Afalse" ]; then
  echo "spas_sage_attn is already up to date (version $spas_sage_attn_version), skipping compilation"
  exit 0
fi

echo "Compiling spas_sage_attn"

cd /comfy/mnt
bb="venv/.build_base.txt"
if [ ! -f $bb ]; then error_exit "${bb} not found"; fi
BUILD_BASE=$(cat $bb)


if [ ! -d src ]; then mkdir src; fi
cd src

mkdir -p ${BUILD_BASE}
if [ ! -d ${BUILD_BASE} ]; then error_exit "${BUILD_BASE} not found"; fi
cd ${BUILD_BASE}

dd="/comfy/mnt/src/${BUILD_BASE}/SpargeAttn"

if [ -d $dd ]; then
  echo "SpargeAttn source already present, deleting $dd to force reinstallation"
  rm -rf $dd
fi
git clone https://github.com/thu-ml/SpargeAttn
cd SpargeAttn
pip3 install -e . || error_exit "Failed to install SpargeAttn"

exit 0
