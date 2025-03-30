#!/bin/bash

script_name=$(basename $0)

# This script will install NVIDIA development tools
#
# At the end of the run, we are saving the environment variables to /tmp/comfy_${script_name}_env.txt
# so they can be used by the init.bash script

set -e

error_exit() {
  echo -n "!! ERROR: "
  echo $*
  echo "!! Exiting script (ID: $$)"
  exit 1
}

check_nvcc() {
  if ! command -v nvcc &> /dev/null; then
    return 1
  fi
  return 0
}

save_env() {
  tosave=$1
  echo "-- Saving environment variables to $tosave"
  env | sort > "$tosave"
}

skip_install=false
echo "Checking if nvcc is available"
if ! check_nvcc; then
  echo " !! nvcc not found, performing installation"
else
  echo " ++ nvcc found, skipping installation, only setting environment variables"
  skip_install=true
fi

echo "Obtaining build base"
cd /comfy/mnt
bb="venv/.build_base.txt"
if [ ! -f $bb ]; then error_exit "${bb} not found"; fi
BUILD_BASE=$(cat $bb)
if [ "A$BUILD_BASE" = "A" ]; then error_exit "BUILD_BASE is empty"; fi

echo " ++ Build base: ${BUILD_BASE}"

# Fix dpkg lock
if [ -f /var/lib/dpkg/lock ]; then
  sudo rm /var/lib/dpkg/lock
  sudo dpkg --configure -a
fi


# ubuntu22_cuda12.3.2
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.3.2/ubuntu2204/devel/Dockerfile
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.3.2/ubuntu2204/devel/cudnn9/Dockerfile
if [ "A$BUILD_BASE" = "Aubuntu22_cuda12.3.2" ]; then
  # CUDNN installed in base image
  export CHECK_NV_CUDNN_VERSION="9.0.0.312"
  if [ "A$CHECK_NV_CUDNN_VERSION" != "A$NV_CUDNN_VERSION" ]; then error_exit "NV_CUDNN_VERSION mismatch: ${CHECK_NV_CUDNN_VERSION} != ${NV_CUDNN_VERSION}"; fi

  export NV_CUDA_LIB_VERSION="12.3.2-1"
  export NV_CUDA_CUDART_DEV_VERSION="12.3.101-1"
  export NV_NVML_DEV_VERSION="12.3.101-1"
  export NV_LIBCUSPARSE_DEV_VERSION="12.2.0.103-1"
  export NV_LIBNPP_DEV_VERSION="12.2.3.2-1"
  export NV_LIBNPP_DEV_PACKAGE="libnpp-dev-12-3=${NV_LIBNPP_DEV_VERSION}"
  export NV_LIBCUBLAS_DEV_VERSION="12.3.4.1-1"
  export NV_LIBCUBLAS_DEV_PACKAGE_NAME="libcublas-dev-12-3"
  export NV_LIBCUBLAS_DEV_PACKAGE="${NV_LIBCUBLAS_DEV_PACKAGE_NAME}=${NV_LIBCUBLAS_DEV_VERSION}"
  export NV_CUDA_NSIGHT_COMPUTE_VERSION="12.3.2-1"
  export NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE="cuda-nsight-compute-12-3=${NV_CUDA_NSIGHT_COMPUTE_VERSION}"
  export NV_NVPROF_VERSION="12.3.101-1"
  export NV_NVPROF_DEV_PACKAGE="cuda-nvprof-12-3=${NV_NVPROF_VERSION}"
  export NV_LIBNCCL_DEV_PACKAGE_NAME="libnccl-dev"
  export NV_LIBNCCL_DEV_PACKAGE_VERSION="2.20.3-1"
  export NCCL_VERSION="2.20.3-1"
  export NV_LIBNCCL_DEV_PACKAGE "${NV_LIBNCCL_DEV_PACKAGE_NAME}=${NV_LIBNCCL_DEV_PACKAGE_VERSION}+cuda12.3"
  export NV_CUDNN_PACKAGE_DEV="libcudnn9-dev-cuda-12=${NV_CUDNN_VERSION}-1"

  if [ "A$skip_install" = "Afalse" ]; then
    sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
      cuda-cudart-dev-12-3=${NV_CUDA_CUDART_DEV_VERSION} \
      cuda-command-line-tools-12-3=${NV_CUDA_LIB_VERSION} \
      cuda-minimal-build-12-3=${NV_CUDA_LIB_VERSION} \
      cuda-libraries-dev-12-3=${NV_CUDA_LIB_VERSION} \
      cuda-nvml-dev-12-3=${NV_NVML_DEV_VERSION} \
      ${NV_NVPROF_DEV_PACKAGE} \
      ${NV_LIBNPP_DEV_PACKAGE} \
      libcusparse-dev-12-3=${NV_LIBCUSPARSE_DEV_VERSION} \
      ${NV_LIBCUBLAS_DEV_PACKAGE} \
      ${NV_LIBNCCL_DEV_PACKAGE} \
      ${NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE} \
      ${NV_CUDNN_PACKAGE_DEV} \
      nvidia-cuda-toolkit \
      build-essential \
    && sudo apt-mark hold ${NV_LIBCUBLAS_DEV_PACKAGE_NAME} ${NV_LIBNCCL_DEV_PACKAGE_NAME} \
    && sudo rm -rf /var/lib/apt/lists/*
  fi
fi


# ubuntu22_cuda12.4.1
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.4.1/ubuntu2204/devel/Dockerfile
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.4.1/ubuntu2204/devel/cudnn/Dockerfile
if [ "A$BUILD_BASE" = "Aubuntu22_cuda12.4.1" ]; then
  # CUDNN installed in base image
  export CHECK_NV_CUDNN_VERSION="9.1.0.70-1"
  if [ "A$CHECK_NV_CUDNN_VERSION" != "A$NV_CUDNN_VERSION" ]; then error_exit "NV_CUDNN_VERSION mismatch: ${CHECK_NV_CUDNN_VERSION} != ${NV_CUDNN_VERSION}"; fi

  export NV_CUDA_LIB_VERSION="12.4.1-1"
  export NV_CUDA_CUDART_DEV_VERSION="12.4.127-1"
  export NV_NVML_DEV_VERSION="12.4.127-1"
  export NV_LIBCUSPARSE_DEV_VERSION="12.3.1.170-1"
  export NV_LIBNPP_DEV_VERSION="12.2.5.30-1"
  export NV_LIBNPP_DEV_PACKAGE="libnpp-dev-12-4=${NV_LIBNPP_DEV_VERSION}"
  export NV_LIBCUBLAS_DEV_VERSION="12.4.5.8-1"
  export NV_LIBCUBLAS_DEV_PACKAGE_NAME="libcublas-dev-12-4"
  export NV_LIBCUBLAS_DEV_PACKAGE="${NV_LIBCUBLAS_DEV_PACKAGE_NAME}=${NV_LIBCUBLAS_DEV_VERSION}"
  export NV_CUDA_NSIGHT_COMPUTE_VERSION="12.4.1-1"
  export NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE="cuda-nsight-compute-12-4=${NV_CUDA_NSIGHT_COMPUTE_VERSION}"
  export NV_NVPROF_VERSION="12.4.127-1"
  export NV_NVPROF_DEV_PACKAGE="cuda-nvprof-12-4=${NV_NVPROF_VERSION}"
  export NV_LIBNCCL_DEV_PACKAGE_NAME="libnccl-dev"
  export NV_LIBNCCL_DEV_PACKAGE_VERSION="2.21.5-1"
  export NCCL_VERSION="2.21.5-1"
  export NV_LIBNCCL_DEV_PACKAGE="${NV_LIBNCCL_DEV_PACKAGE_NAME}=${NV_LIBNCCL_DEV_PACKAGE_VERSION}+cuda12.4"
  export NV_CUDNN_PACKAGE_DEV="libcudnn9-dev-cuda-12=${NV_CUDNN_VERSION}"
  
  if [ "A$skip_install" = "Afalse" ]; then
    sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
      cuda-cudart-dev-12-4=${NV_CUDA_CUDART_DEV_VERSION} \
      cuda-command-line-tools-12-4=${NV_CUDA_LIB_VERSION} \
      cuda-minimal-build-12-4=${NV_CUDA_LIB_VERSION} \
      cuda-libraries-dev-12-4=${NV_CUDA_LIB_VERSION} \
      cuda-nvml-dev-12-4=${NV_NVML_DEV_VERSION} \
      ${NV_NVPROF_DEV_PACKAGE} \
      ${NV_LIBNPP_DEV_PACKAGE} \
      libcusparse-dev-12-4=${NV_LIBCUSPARSE_DEV_VERSION} \
      ${NV_LIBCUBLAS_DEV_PACKAGE} \
        ${NV_LIBNCCL_DEV_PACKAGE} \
      ${NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE} \
      ${NV_CUDNN_PACKAGE_DEV} \
      nvidia-cuda-toolkit \
      build-essential \
    && sudo apt-mark hold ${NV_LIBCUBLAS_DEV_PACKAGE_NAME} ${NV_LIBNCCL_DEV_PACKAGE_NAME} \
    && sudo rm -rf /var/lib/apt/lists/*
  fi
fi


# ubuntu24_cuda12.5.1
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.5.1/ubuntu2404/devel/Dockerfile
if [ "A${BUILD_BASE}" = "Aubuntu24_cuda12.5.1" ]; then
  # CUDNN installed in base image
  export CHECK_NV_CUDNN_VERSION="9.3.0.75-1"
  if [ "A$CHECK_NV_CUDNN_VERSION" != "A$NV_CUDNN_VERSION" ]; then error_exit "NV_CUDNN_VERSION mismatch: ${CHECK_NV_CUDNN_VERSION} != ${NV_CUDNN_VERSION}"; fi

  export NV_CUDA_LIB_VERSION "12.5.1-1"
  export NV_CUDA_CUDART_DEV_VERSION 12.5.82-1
  export NV_NVML_DEV_VERSION 12.5.82-1
  export NV_LIBCUSPARSE_DEV_VERSION 12.5.1.3-1
  export NV_LIBNPP_DEV_VERSION 12.3.0.159-1
  export NV_LIBNPP_DEV_PACKAGE libnpp-dev-12-5=${NV_LIBNPP_DEV_VERSION}
  export NV_LIBCUBLAS_DEV_VERSION 12.5.3.2-1
  export NV_LIBCUBLAS_DEV_PACKAGE_NAME libcublas-dev-12-5
  export NV_LIBCUBLAS_DEV_PACKAGE ${NV_LIBCUBLAS_DEV_PACKAGE_NAME}=${NV_LIBCUBLAS_DEV_VERSION}
  export NV_CUDA_NSIGHT_COMPUTE_VERSION 12.5.1-1
  export NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE cuda-nsight-compute-12-5=${NV_CUDA_NSIGHT_COMPUTE_VERSION}
  export NV_NVPROF_VERSION 12.5.82-1
  export NV_NVPROF_DEV_PACKAGE cuda-nvprof-12-5=${NV_NVPROF_VERSION}
  export NV_CUDNN_PACKAGE_DEV="libcudnn9-dev-cuda-12=${NV_CUDNN_VERSION}"

  if [ "A$skip_install" = "Afalse" ]; then
    sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
      cuda-cudart-dev-12-5=${NV_CUDA_CUDART_DEV_VERSION} \
      cuda-command-line-tools-12-5=${NV_CUDA_LIB_VERSION} \
      cuda-minimal-build-12-5=${NV_CUDA_LIB_VERSION} \
      cuda-libraries-dev-12-5=${NV_CUDA_LIB_VERSION} \
      cuda-nvml-dev-12-5=${NV_NVML_DEV_VERSION} \
      ${NV_NVPROF_DEV_PACKAGE} \
      ${NV_LIBNPP_DEV_PACKAGE} \
      libcusparse-dev-12-5=${NV_LIBCUSPARSE_DEV_VERSION} \
      ${NV_LIBCUBLAS_DEV_PACKAGE} \
      ${NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE} \
      ${NV_CUDNN_PACKAGE_DEV} \
      nvidia-cuda-toolkit \
      build-essential \
    && sudo apt-mark hold ${NV_LIBCUBLAS_DEV_PACKAGE_NAME} \
    && sudo rm -rf /var/lib/apt/lists/*
  fi
fi


# ubuntu24_cuda12.6.3
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.6.3/ubuntu2404/devel/Dockerfile
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.6.3/ubuntu2404/devel/cudnn/Dockerfile?ref_type=heads
if [ "A${BUILD_BASE}" = "Aubuntu24_cuda12.6.3" ]; then
  # CUDNN installed in base image
  export CHECK_NV_CUDNN_VERSION="9.5.1.17-1"
  if [ "A$CHECK_NV_CUDNN_VERSION" != "A$NV_CUDNN_VERSION" ]; then error_exit "NV_CUDNN_VERSION mismatch: ${CHECK_NV_CUDNN_VERSION} != ${NV_CUDNN_VERSION}"; fi

  export NV_CUDA_CUDART_DEV_VERSION="12.6.77-1"
  export NV_NVML_DEV_VERSION="12.6.77-1"
  export NV_LIBCUSPARSE_DEV_VERSION="12.5.4.2-1"
  export NV_LIBNPP_DEV_VERSION="12.3.1.54-1"
  export NV_LIBNPP_DEV_PACKAGE="libnpp-dev-12-6=${NV_LIBNPP_DEV_VERSION}"
  export NV_LIBCUBLAS_DEV_VERSION="12.6.4.1-1"
  export NV_LIBCUBLAS_DEV_PACKAGE_NAME="libcublas-dev-12-6"
  export NV_LIBCUBLAS_DEV_PACKAGE="${NV_LIBCUBLAS_DEV_PACKAGE_NAME}=${NV_LIBCUBLAS_DEV_VERSION}"
  export NV_CUDA_NSIGHT_COMPUTE_VERSION="12.6.3-1"
  export NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE="cuda-nsight-compute-12-6=${NV_CUDA_NSIGHT_COMPUTE_VERSION}"
  export NV_NVPROF_VERSION="12.6.80-1"
  export NV_NVPROF_DEV_PACKAGE="cuda-nvprof-12-6=${NV_NVPROF_VERSION}"
  export NV_LIBNCCL_DEV_PACKAGE_NAME="libnccl-dev"
  export NV_LIBNCCL_DEV_PACKAGE_VERSION="2.23.4-1"
  export NCCL_VERSION="2.23.4-1"
  export NV_LIBNCCL_DEV_PACKAGE="${NV_LIBNCCL_DEV_PACKAGE_NAME}=${NV_LIBNCCL_DEV_PACKAGE_VERSION}+cuda12.6"
  export NV_CUDNN_PACKAGE_DEV="libcudnn9-dev-cuda-12=${NV_CUDNN_VERSION}"

  if [ "A$skip_install" = "Afalse" ]; then
    sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
    cuda-cudart-dev-12-6=${NV_CUDA_CUDART_DEV_VERSION} \
    cuda-command-line-tools-12-6=${NV_CUDA_LIB_VERSION} \
    cuda-minimal-build-12-6=${NV_CUDA_LIB_VERSION} \
    cuda-libraries-dev-12-6=${NV_CUDA_LIB_VERSION} \
    cuda-nvml-dev-12-6=${NV_NVML_DEV_VERSION} \
    ${NV_NVPROF_DEV_PACKAGE} \
    ${NV_LIBNPP_DEV_PACKAGE} \
    libcusparse-dev-12-6=${NV_LIBCUSPARSE_DEV_VERSION} \
    ${NV_LIBCUBLAS_DEV_PACKAGE} \
    ${NV_LIBNCCL_DEV_PACKAGE} \
    ${NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE} \
    ${NV_CUDNN_PACKAGE_DEV} \
    nvidia-cuda-toolkit \
    build-essential \
  && sudo apt-mark hold ${NV_LIBCUBLAS_DEV_PACKAGE_NAME} ${NV_LIBNCCL_DEV_PACKAGE_NAME} \
  && sudo rm -rf /var/lib/apt/lists/*
  fi
fi

# ubuntu24_cuda12.8
# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.8.1/ubuntu2404/devel/Dockerfile?ref_type=heads
# https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/12.8.1/ubuntu2404/devel/cudnn
if [ "A${BUILD_BASE}" = "Aubuntu24_cuda12.8" ]; then
  # CuDNN installed in base image
  export CHECK_NV_CUDNN_VERSION="9.8.0.87-1"
  if [ "A$CHECK_NV_CUDNN_VERSION" != "A$NV_CUDNN_VERSION" ]; then error_exit "NV_CUDNN_VERSION mismatch: ${CHECK_NV_CUDNN_VERSION} != ${NV_CUDNN_VERSION}"; fi

  export NV_CUDA_LIB_VERSION="12.8.1-1"
  export NV_CUDA_CUDART_DEV_VERSION="12.8.90-1"
  export NV_NVML_DEV_VERSION="12.8.90-1"
  export NV_LIBCUSPARSE_DEV_VERSION="12.5.8.93-1"
  export NV_LIBNPP_DEV_VERSION="12.3.3.100-1"
  export NV_LIBNPP_DEV_PACKAGE="libnpp-dev-12-8=${NV_LIBNPP_DEV_VERSION}"
  export NV_LIBCUBLAS_DEV_VERSION="12.8.4.1-1"
  export NV_LIBCUBLAS_DEV_PACKAGE_NAME="libcublas-dev-12-8"
  export NV_LIBCUBLAS_DEV_PACKAGE="${NV_LIBCUBLAS_DEV_PACKAGE_NAME}=${NV_LIBCUBLAS_DEV_VERSION}"
  export NV_CUDA_NSIGHT_COMPUTE_VERSION="12.8.1-1"
  export NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE="cuda-nsight-compute-12-8=${NV_CUDA_NSIGHT_COMPUTE_VERSION}"
  export NV_NVPROF_VERSION="12.8.90-1"
  export NV_NVPROF_DEV_PACKAGE="cuda-nvprof-12-8=${NV_NVPROF_VERSION}"
  export NV_LIBNCCL_DEV_PACKAGE_NAME="libnccl-dev"
  export NV_LIBNCCL_DEV_PACKAGE_VERSION="2.25.1-1"
  export NCCL_VERSION="2.25.1-1"
  export NV_LIBNCCL_DEV_PACKAGE="${NV_LIBNCCL_DEV_PACKAGE_NAME}=${NV_LIBNCCL_DEV_PACKAGE_VERSION}+cuda12.8"
  export NV_CUDNN_PACKAGE_DEV="libcudnn9-dev-cuda-12=${NV_CUDNN_VERSION}"

  if [ "A$skip_install" = "Afalse" ]; then
    sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
      cuda-cudart-dev-12-8=${NV_CUDA_CUDART_DEV_VERSION} \
      cuda-command-line-tools-12-8=${NV_CUDA_LIB_VERSION} \
      cuda-minimal-build-12-8=${NV_CUDA_LIB_VERSION} \
      cuda-libraries-dev-12-8=${NV_CUDA_LIB_VERSION} \
      cuda-nvml-dev-12-8=${NV_NVML_DEV_VERSION} \
      ${NV_NVPROF_DEV_PACKAGE} \
      ${NV_LIBNPP_DEV_PACKAGE} \
      libcusparse-dev-12-8=${NV_LIBCUSPARSE_DEV_VERSION} \
      ${NV_LIBCUBLAS_DEV_PACKAGE} \
      ${NV_LIBNCCL_DEV_PACKAGE} \
      ${NV_CUDA_NSIGHT_COMPUTE_DEV_PACKAGE} \
      ${NV_CUDNN_PACKAGE_DEV} \
      nvidia-cuda-toolkit \
      build-essential \
    && sudo apt-mark hold ${NV_LIBCUBLAS_DEV_PACKAGE_NAME} ${NV_LIBNCCL_DEV_PACKAGE_NAME} \
    && sudo rm -rf /var/lib/apt/lists/*
  fi
fi

if ! check_nvcc; then
  error_exit "nvcc not found after installation"
fi

it="/usr/local/cuda/lib64/stubs"
if [ -d $it ]; then
  echo "== Adding CUDA stubs to library path"
  if [ "A${LIBRARY_PATH}" = "A" ]; then
    export LIBRARY_PATH=$it
  else
    export LIBRARY_PATH=${LIBRARY_PATH}:$it
  fi
fi

save_env /tmp/comfy_${script_name}_env.txt
exit 0
