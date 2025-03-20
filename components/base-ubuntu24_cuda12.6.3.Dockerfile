FROM nvidia/cuda:12.6.3-runtime-ubuntu24.04

# Extended from https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.6.3/ubuntu2404/runtime/cudnn/Dockerfile
ENV NV_CUDNN_VERSION=9.5.1.17-1
ENV NV_CUDNN_PACKAGE_NAME="libcudnn9-cuda-12"
ENV NV_CUDNN_PACKAGE="${NV_CUDNN_PACKAGE_NAME}=${NV_CUDNN_VERSION}"

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ${NV_CUDNN_PACKAGE} \
    && apt-mark hold ${NV_CUDNN_PACKAGE_NAME}

ARG BASE_DOCKER_FROM=nvidia/cuda:12.6.3-runtime-ubuntu24.04

