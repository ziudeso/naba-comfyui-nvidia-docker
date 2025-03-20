#!/bin/bash

set -e

error_exit() {
  echo -n "!! ERROR: "
  echo $*
  echo "!! Exiting script (ID: $$)"
  exit 1
}

ok_exit() {
  echo $*
  echo "++ Exiting script (ID: $$)"
  exit 0
}

whoami=`whoami`
script_dir=$(dirname $0)
script_name=$(basename $0)
echo ""; echo ""
echo "======================================"
echo "=================== Starting script (ID: $$)"
echo "== Running ${script_name} in ${script_dir} as ${whoami}"
script_fullname=$0
cmd_wuid=$1
cmd_wgid=$2
cmd_seclvl=$3
cmd_basedir=$4
cmd_cmdline_base=$5
cmd_cmdline_extra=$6
echo "  - script_fullname: ${script_fullname}"
echo "  - cmd_wuid: ${cmd_wuid}"
echo "  - cmd_wgid: ${cmd_wgid}"
echo "  - cmd_seclvl: ${cmd_seclvl}"
echo "  - cmd_basedir: ${cmd_basedir}"
echo "  - cmd_cmdline_base: ${cmd_cmdline_base}"
echo "  - cmd_cmdline_extra: ${cmd_cmdline_extra}"
echo "======================================"
ignore_value="VALUE_TO_IGNORE"

# everyone can read our files by default
umask 0022

# Write a world-writeable file (preferably inside /tmp -- ie within the container)
write_worldtmpfile() {
  tmpfile=$1
  if [ -z "${tmpfile}" ]; then error_exit "write_worldfile: missing argument"; fi
  if [ -f $tmpfile ]; then rm -f $tmpfile; fi
  echo -n $2 > ${tmpfile}
  chmod 777 ${tmpfile}
}

itdir=/tmp/comfy_init
if [ ! -d $itdir ]; then mkdir $itdir; chmod 777 $itdir; fi
if [ ! -d $itdir ]; then error_exit "Failed to create $itdir"; fi

it=$itdir/comfy_cmdline_base
if [ ! -z "$cmd_cmdline_base" ]; then COMFY_CMDLINE_BASE=`cat $cmd_cmdline_base`; else cmd_cmdline_base=$it;  fi
if [ -z ${COMFY_CMDLINE_BASE+x} ]; then COMFY_CMDLINE_BASE="python3 ./main.py --listen 0.0.0.0 --disable-auto-launch"; fi
if [ !  -z ${COMFY_CMDLINE_BASE+x} ]; then write_worldtmpfile $it "$COMFY_CMDLINE_BASE"; fi
if [ ! -f $it ]; then error_exit "$it missing, exiting"; fi
COMFY_CMDLINE_BASE=`cat $it`
echo "-- COMFY_CMDLINE_BASE: \"${COMFY_CMDLINE_BASE}\""

# support previous variable
if [ ! -z ${COMFY_CMDLINE_XTRA+x} ]; then COMFY_CMDLINE_EXTRA="${COMFY_CMDLINE_XTRA}"; fi
it=$itdir/comfy_cmdline_extra
if [ ! -z "$cmd_cmdline_extra" ]; then COMFY_CMDLINE_EXTRA=`cat $cmd_cmdline_extra`; else cmd_cmdline_extra=$it; fi
if [ -z ${COMFY_CMDLINE_EXTRA+x} ]; then COMFY_CMDLINE_EXTRA=""; fi
if [ ! -z ${COMFY_CMDLINE_EXTRA+x} ]; then write_worldtmpfile $it "$COMFY_CMDLINE_EXTRA"; fi
if [ ! -f $it ]; then error_exit "$it missing, exiting"; fi
COMFY_CMDLINE_EXTRA=`cat $it`
echo "-- COMFY_CMDLINE_EXTRA: \"${COMFY_CMDLINE_EXTRA}\""

# Get user and group id
if [ -z "$WANTED_UID" ]; then WANTED_UID=$cmd_wuid; fi
if [ -z "$WANTED_UID" ]; then echo "-- No WANTED_UID provided, using comfy user default of 1024"; WANTED_UID=1024; fi
if [ -z "$WANTED_GID" ]; then WANTED_GID=$cmd_wgid; fi
if [ -z "$WANTED_GID" ]; then echo "-- No WANTED_GID provided, using comfy user default of 1024"; WANTED_GID=1024; fi

# Get security level
if [ -z "$SECURITY_LEVEL" ]; then SECURITY_LEVEL=$cmd_seclvl; fi
if [ -z "$SECURITY_LEVEL" ]; then echo "-- No SECURITY_LEVEL provided, using comfy default of normal"; SECURITY_LEVEL="normal"; fi

# Get base directory
if [ -z "$BASE_DIRECTORY" ]; then BASE_DIRECTORY=$cmd_basedir; fi
if [ -z "$BASE_DIRECTORY" ]; then BASE_DIRECTORY=$ignore_value; fi
if [ ! -z "$BASE_DIRECTORY" ]; then if [ $BASE_DIRECTORY != $ignore_value ] && [ ! -d "$BASE_DIRECTORY" ]; then error_exit "BASE_DIRECTORY requested but not found or not a directory ($BASE_DIRECTORY)"; fi; fi

# extract base image information
it=/etc/image_base.txt
if [ ! -f $it ]; then error_exit "$it missing, exiting"; fi
echo "-- Base image details (from $it):"; cat $it

# extract comfy user directory
it=/etc/comfyuser_dir
if [ ! -f $it ]; then error_exit "$it missing, exiting"; fi
COMFYUSER_DIR=`cat $it`
echo "-- COMFYUIUSER_DIR: \"${COMFYUSER_DIR}\""
if test -z ${COMFYUSER_DIR}; then error_exit "Empty COMFYUSER_DIR variable"; fi

# extract build base information
it=/etc/build_base.txt
if [ ! -f $it ]; then error_exit "$it missing, exiting"; fi
BUILD_BASE=`cat $it`
BUILD_BASE_FILE=$it
BUILD_BASE_SPECIAL="ubuntu22_cuda12.3.2" # this is a special value: when this feature was introduced, will be used to mark exisitng venv if the marker is not present
BUILD_BASE_RTX50xx="ubuntu24_cuda12.8"
echo "-- BUILD_BASE: \"${BUILD_BASE}\""
if test -z ${BUILD_BASE}; then error_exit "Empty BUILD_BASE variable"; fi

# Check user id and group id
new_gid=`id -g`
new_uid=`id -u`
echo "== user ($whoami)"
echo "  uid: $new_uid / WANTED_UID: $WANTED_UID"
echo "  gid: $new_gid / WANTED_GID: $WANTED_GID"

# comfytoo is a specfiic user not existing by default on ubuntu, we can check its whomai
if [ "A${whoami}" == "Acomfytoo" ]; then 
  echo "-- Running as comfytoo, will switch comfy to the desired UID/GID"
  # The script is started as comfytoo -- UID/GID 1025/1025

  if [ ! -z $FORCE_CHOWN ]; then # any value works, empty value means disabled
    echo "-- Force chown mode enabled, will force change directory ownership as comfy user during script rerun (might be slow)"
    sudo touch /etc/comfy_force_chown
  fi

  # We are altering the UID/GID of the comfy user to the desired ones and restarting as comfy
  # using usermod for the already create comfy user, knowing it is not already in use
  # per usermod manual: "You must make certain that the named user is not executing any processes when this command is being executed"
  sudo groupmod -o -g ${WANTED_GID} comfy || error_exit "Failed to set GID of comfy user"
  sudo usermod -o -u ${WANTED_UID} comfy || error_exit "Failed to set UID of comfy user"
  sudo chown -R ${WANTED_UID}:${WANTED_GID} /home/comfy || error_exit "Failed to set owner of /home/comfy"
  sudo chown ${WANTED_UID}:${WANTED_GID} ${COMFYUSER_DIR} || error_exit "Failed to set owner of ${COMFYUSER_DIR}"
  # restart the script as comfy set with the correct UID/GID this time
  echo "-- Restarting as comfy user with UID ${WANTED_UID} GID ${WANTED_GID}"
  sudo su comfy $script_fullname ${WANTED_UID} ${WANTED_GID} ${SECURITY_LEVEL} ${BASE_DIRECTORY} ${cmd_cmdline_base} ${cmd_cmdline_extra} || error_exit "subscript failed"
  ok_exit "Clean exit"
fi

# If we are here, the script is started as another user than comfytoo
# because the whoami value for the comfy user can be any existing user, we can not check against it
# instead we check if the UID/GID are the expected ones
if [ "$WANTED_GID" != "$new_gid" ]; then error_exit "comfy MUST be running as UID ${WANTED_UID} GID ${WANTED_GID}, current UID ${new_uid} GID ${new_gid}"; fi
if [ "$WANTED_UID" != "$new_uid" ]; then error_exit "comfy MUST be running as UID ${WANTED_UID} GID ${WANTED_GID}, current UID ${new_uid} GID ${new_gid}"; fi

# We are therefore running as comfy
echo ""; echo "== Running as comfy"

########## 'comfy' specific section below

dir_validate() { # arg1 = directory to validate / arg2 = "mount" or ""; a "mount" can not be chmod'ed
  testdir=$1

  if [ ! -d "$testdir" ]; then error_exit "Directory $testdir not found (or not a directory)"; fi

  if [ "A$2" == "A" ] && [ -f /etc/comfy_force_chown ]; then
    echo "  ++ Attempting to recursively set ownership of $testdir to ${WANTED_UID}:${WANTED_GID} (might take a long time)"
    sudo chown -R ${WANTED_UID}:${WANTED_GID} "$testdir" || error_exit "Failed to set owner of $testdir"
  fi

  # check if the directory is owned by WANTED_UID/WANTED_GID
  if [ "$(stat -c %u:%g "$testdir")" != "${WANTED_UID}:${WANTED_GID}" ]; then
    xtra_txt=" -- recommended to start with the FORCE_CHOWN=yes environment varable enabled"
    if [ "A$2" == "Amount" ]; then
      xtra_txt=" -- FORCE_CHOWN will not work for this folder, it is a PATH mounted at container startup and requires a manual fix: chown -R ${WANTED_UID}:${WANTED_GID} foldername"
    fi
    error_exit "Directory $testdir owned by unexpected user/group, expected ${WANTED_UID}:${WANTED_GID}, actual $(stat -c %u:%g "$testdir")$xtra_txt"
  fi

  if [ ! -w "$testdir" ]; then error_exit "Directory $testdir not writeable"; fi
  if [ ! -x "$testdir" ]; then error_exit "Directory $testdir not executable"; fi
  if [ ! -r "$testdir" ]; then error_exit "Directory $testdir not readable"; fi
}

## Path: ${COMFYUSER_DIR}/mnt
echo "== Testing write access as the comfy user to the run directory"
it_dir="${COMFYUSER_DIR}/mnt"
dir_validate "${it_dir}" "mount"
it="${it_dir}/.testfile"; touch $it && rm -f $it || error_exit "Failed to write to $it_dir"

##
echo ""; echo "== Obtaining the latest version of ComfyUI (if folder not present)"
cd $it_dir # ${COMFYUSER_DIR}/mnt -- stay here for the following checks/setups
if [ ! -d "ComfyUI" ]; then
  echo ""; echo "== Cloning ComfyUI"
  git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI || error_exit "ComfyUI clone failed"
fi

##
echo ""; echo "== Confirm the ComfyUI directory is present and we can write to it"
it_dir="${COMFYUSER_DIR}/mnt/ComfyUI"
dir_validate "${it_dir}" 
it="${it_dir}/.testfile" && rm -f $it || error_exit "Failed to write to ComfyUI directory as the comfy user"

##
echo ""; echo "== Check on BASE_DIRECTORY (if used)"
if [ "$BASE_DIRECTORY" == "$ignore_value" ]; then BASE_DIRECTORY=""; fi
if [ ! -z "$BASE_DIRECTORY" ]; then 
  it_dir=$BASE_DIRECTORY
  dir_validate "${it_dir}" "mount"
  it="${it_dir}/.testfile" && touch $it && rm -f $it || error_exit "Failed to write to BASE_DIRECTORY"
fi

##
echo ""; echo "== Validate/Create HugginFace directory"
it_dir="${COMFYUSER_DIR}/mnt/HF"
if [ ! -d "${it_dir}" ]; then
  echo "";echo "== Creating HF directory"
  mkdir -p ${it_dir}
fi
dir_validate "${it_dir}"
it=${it_dir}/.testfile && rm -f $it || error_exit "Failed to write to HF directory as the comfy user"
export HF_HOME=${COMFYUSER_DIR}/mnt/HF

# Attempting to support multiple build bases
# the venv directory is specific to the build base
# we are placing a marker file in the venv directory to match it to a build base
# if the marker is not for container's build base, we rename the venv directory to avoid conflicts

## Current path: ${COMFYUSER_DIR}/mnt
echo ""; echo "== if a venv is present, confirm we can write to it"
it_dir="${COMFYUSER_DIR}/mnt/venv"
if [ -d "${it_dir}" ]; then
  dir_validate "${it_dir}"
  it=${it_dir}/.testfile && rm -f $it || error_exit "Failed to write to venv directory as the comfy user"
  # use the special value to mark existing venv if the marker is not present
  it=${it_dir}/.build_base.txt; if [ ! -f $it ]; then echo $BUILD_BASE_SPECIAL > $it; fi
fi

##
echo ""; echo "== Matching any existing venv to container's BUILD_BASE (${BUILD_BASE})"
SWITCHED_VENV=True # this is a marker to indicate that we have switched to a different venv, which is set unless we re-use the same venv as before (see below)
# Check for an existing venv; if present, is it the proper one -- ie does its .build_base.txt match the container's BUILD_BASE_FILE?
if [ -d venv ]; then
  it=venv/.build_base.txt
  venv_bb=`cat $it`

  echo ""
  if cmp --silent $it $BUILD_BASE_FILE; then
    echo "== venv is for this BUILD_BASE (${BUILD_BASE})"
    SWITCHED_VENV=False
  else
    echo "== venv ($venv_bb) is not for this BUILD_BASE (${BUILD_BASE}), renaming it and seeing if a valid one is present"
    mv venv venv-${venv_bb} || error_exit "Failed to rename venv to venv-${venv_bb}"

    if [ -d venv-${BUILD_BASE} ]; then
      echo "== Existing venv (${BUILD_BASE}) found, attempting to use it"
      mv venv-${BUILD_BASE} venv || error_exit "Failed to rename ven-${BUILD_BASE} to venv"
    fi
  fi
fi

##
echo ""; echo "== Create virtualenv for installation (if not present)"
if [ ! -d "venv" ]; then
  echo ""; echo "== Creating virtualenv"
  python3 -m venv venv || error_exit "Virtualenv creation failed"
  echo $BUILD_BASE > venv/.build_base.txt
fi

##
echo ""; echo "== Confirming venv is writeable"
it_dir="${COMFYUSER_DIR}/mnt/venv"
dir_validate "${it_dir}"
it="${it_dir}/.testfile" && rm -f $it || error_exit "Failed to write to venv directory as the comfy user"

##
echo ""; echo "== Activate the virtualenv and upgrade pip"
it="${it_dir}/bin/activate"
if [ ! -f "$it" ]; then error_exit "virtualenv not created, please erase any venv directory"; fi
echo ""; echo "  == Activating virtualenv"
source "$it" || error_exit "Virtualenv activation failed"
echo ""; echo "  == Upgrading pip"
pip3 install --upgrade pip || error_exit "Pip upgrade failed"

# extent the PATH to include the user local bin directory
export PATH=${COMFYUSER_DIR}/.local/bin:${PATH}

# Verify the variables
echo ""; echo ""; echo "==================="
echo "== Environment details:"
echo -n "  PATH: "; echo $PATH
echo -n "  Python version: "; python3 --version
echo -n "  Pip version: "; pip3 --version
echo -n "  python bin: "; which python3
echo -n "  pip bin: "; which pip3
echo -n "  git bin: "; which git

# CUDA 12.8 special case
if [[ "${BUILD_BASE}" == "${BUILD_BASE_RTX50xx}"* ]]; then
  # https://github.com/comfyanonymous/ComfyUI/discussions/6643
  echo ""; echo "!! This is a special case, we are going to install the requirements for RTX 50xx series GPUs"
  echo "  -- Installation CUDA 12.8 Torch from nightly"
  pip3 install --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
fi

# Install ComfyUI's requirements
cd ComfyUI
it=requirements.txt
echo ""; echo "== Installing/Updating from ComfyUI's requirements"
pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r $it || error_exit "ComfyUI requirements install/upgrade failed"
echo ""; echo "== Installing Huggingface Hub"
pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org -U "huggingface_hub[cli]" || error_exit "HuggingFace Hub CLI install/upgrade failed"

export COMFYUI_PATH=`pwd`
echo ""; echo "-- COMFYUI_PATH: ${COMFYUI_PATH}"

# Install ComfyUI Manager if not already present
echo ""
customnodes_dir=${COMFYUI_PATH}/custom_nodes
if [ ! -z "$BASE_DIRECTORY" ]; then it=${BASE_DIRECTORY}/custom_nodes; if [ -d $it ]; then customnodes_dir=$it; fi; fi
cd ${customnodes_dir}
if [ ! -d ComfyUI-Manager ]; then
  echo "== Cloning ComfyUI-Manager (within ${customnodes_dir})"
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git || error_exit "ComfyUI-Manager clone failed"
fi
if [ ! -d ComfyUI-Manager ]; then error_exit "ComfyUI-Manager not found"; fi
echo "== Installing/Updating ComfyUI-Manager's requirements (from ${customnodes_dir}/ComfyUI-Manager/requirements.txt)"
pip3 install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r ${customnodes_dir}/ComfyUI-Manager/requirements.txt || error_exit "ComfyUI-Manager CLI requirements install/upgrade failed" 

# Lower security_level for ComfyUI-Manager to allow access from outside the container
# This is needed to allow the WebUI to be served on 0.0.0.0 ie all interfaces and not just localhost (which would be limited to within the container)
# Please see https://github.com/ltdrdata/ComfyUI-Manager?tab=readme-ov-file#security-policy for more details
# 
# recent releases of ComfyUI-Manager have a config.ini file in the user folder, if this is not present, we expect it in the default folder
cm_conf_user=${COMFYUI_PATH}/user/default/ComfyUI-Manager/config.ini
cm_conf=${COMFYUI_PATH}/custom_nodes/ComfyUI-Manager/config.ini
if [ ! -z "$BASE_DIRECTORY" ]; then it=${BASE_DIRECTORY}/user/default/ComfyUI-Manager/config.ini ; if [ -f $it ]; then cm_conf_user=$it; fi; fi
if [ -f $cm_conf_user ]; then cm_conf=$cm_conf_user; fi
echo ""
if [ ! -f $cm_conf ]; then
  echo "== ComfyUI-Manager $cm_conf file missing, script potentially never run before. You will need to run ComfyUI-Manager a first time for the configuration file to be generated, we can not attempt to update its security level yet -- if this keeps occurring, please let the developer know so he can investigate. Thank you"
else
  echo "  -- Using ComfyUI-Manager config file: $cm_conf"
  perl -p -i -e 's%security_level = \w+%security_level = '${SECURITY_LEVEL}'%g' $cm_conf
  echo -n "  -- ComfyUI-Manager (should show: ${SECURITY_LEVEL}): "
  grep security_level $cm_conf
fi

# Attempt to use ComfyUI Manager CLI to fix all installed nodes -- This must be done within the activated virtualenv
echo ""
if [ "A${SWITCHED_VENV}" == "AFalse" ]; then
  echo "== Skipping ComfyUI-Manager CLI fix as we are re-using the same venv as the last execution"
  echo "  -- If you are experiencing issues with custom nodes, use 'Manager -> Custom Nodes Manager -> Filter: Import Failed -> Try Fix' from the WebUI"
else 
  cm_cli=${COMFYUI_PATH}/custom_nodes/ComfyUI-Manager/cm-cli.py
  if [ ! -z "$BASE_DIRECTORY" ]; then it=${BASE_DIRECTORY}/custom_nodes/ComfyUI-Manager/cm-cli.py ; if [ -f $it ]; then cm_cli=$it; fi; fi
  if [ -f $cm_cli ]; then
    echo "== Running ComfyUI-Manager CLI to fix installed custom nodes"
    python3 $cm_cli fix all || echo "ComfyUI-Manager CLI failed -- in case of issue with custom nodes: use 'Manager -> Custom Nodes Manager -> Filter: Import Failed -> Try Fix' from the WebUI"
  else
    echo "== ComfyUI-Manager CLI not found, skipping"
  fi
fi

# If we are using a base directory... 
if [ ! -z "$BASE_DIRECTORY" ]; then
  if [ ! -d "$BASE_DIRECTORY" ]; then error_exit "BASE_DIRECTORY ($BASE_DIRECTORY) not found or not a directory"; fi
  dir_validate "${BASE_DIRECTORY}" "mount"
  it=${BASE_DIRECTORY}/.testfile && rm -f $it || error_exit "Failed to write to BASE_DIRECTORY"

  echo ""; echo "== Setting base_directory: $BASE_DIRECTORY"

  # List of content to process obtained from https://github.com/comfyanonymous/ComfyUI/pull/6600/files

  # we want to MOVE content from the expected directories into the new base_directory (if those directories do not exist yet)
  # any git pull on the ComfyUI directory will create new folder structure under the source directories but since we have moved existing
  # ones to the new base_directory, the new structure will be ignored
  echo "++ Logic to move content from ComfyUI directories to the new base_directory"
  for i in models input output temp user custom_nodes; do
    in=${COMFYUI_PATH}/$i
    out=${BASE_DIRECTORY}/$i
    if [ -d $in ]; then
      if [ ! -d $out ]; then
        echo "  ++ Moving $in to $out"
        mv $in $out || error_exit "Failed to move $in to $out"
      else
        echo "  -- Both $in (in) and $out (out) exist, skipping move."
        echo "FYI attempting to list files in 'in' that are not in 'out' (empty means no differences):"
        comm -23 <(find $in -type f -printf "%P\n" | sort) <(find $out -type f -printf "%P\n" | sort)
      fi
    else
        if [ ! -d $out ]; then
          echo "  ++ $in not found, $out does not exist: creating destination directory"
          mkdir -p $out || error_exit "Failed to create $out"
        else
          echo "  -- $in not found, $out exists, skipping"
        fi
    fi

    dir_validate "$out"
    it=${out}/.testfile && rm -f $it || error_exit "Failed to write to $out"
  done

  # Next check that all expected directories in models are present and create them otherwise
  echo "  == Checking models directory"
  for i in checkpoints loras vae configs clip_vision style_models diffusers vae_approx gligen upscale_models embeddings hypernetworks photomaker classifiers; do
    it=${BASE_DIRECTORY}/models/$i
    if [ ! -d $it ]; then
      echo "    ++ Creating $it"
      mkdir -p $it || error_exit "Failed to create $it"
    else
      echo "    -- $it already exists, skipping"
    fi

    dir_validate "$it"
    it=${it}/.testfile && rm -f $it || error_exit "Failed to write to $it"
  done

  # and extend the command line using COMFY_CMDLINE_EXTRA (export to be accessible to child processes such as the user script)
  export COMFY_CMDLINE_EXTRA="${COMFY_CMDLINE_EXTRA} --base-directory $BASE_DIRECTORY"
  echo "!! COMFY_CMDLINE_EXTRA extended, make sure to use it in user script (if any): ${COMFY_CMDLINE_EXTRA}"
fi

# Final steps before running ComfyUI
cd ${COMFYUI_PATH}
echo "";echo -n "== Container directory: "; pwd

# Check for a user custom script
it=${COMFYUSER_DIR}/mnt/user_script.bash
echo ""; echo "== Checking for user script: ${it}"
if [ -f $it ]; then
  if [ ! -x $it ]; then
    echo "== Attempting to make user script executable"
    chmod +x $it || error_exit "Failed to make user script executable"
  fi
  echo "  Running user script: ${it}"
  $it
  if [ $? -ne 0 ]; then 
    error_exit "User script failed or exited with an error (possibly on purpose to avoid running the default ComfyUI command)"
  fi
fi

echo ""; echo "==================="
echo "== Running ComfyUI"
# Full list of CLI options at https://github.com/comfyanonymous/ComfyUI/blob/master/comfy/cli_args.py
echo "-- Command line run: ${COMFY_CMDLINE_BASE} ${COMFY_CMDLINE_EXTRA}"
${COMFY_CMDLINE_BASE} ${COMFY_CMDLINE_EXTRA} || error_exit "ComfyUI failed or exited with an error"

ok_exit "Clean exit"
