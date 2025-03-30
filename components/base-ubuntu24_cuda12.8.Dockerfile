FROM nvidia/cuda:12.8.1-runtime-ubuntu24.04

# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.8.1/ubuntu2404/runtime/cudnn/Dockerfile
ENV NV_CUDNN_VERSION=9.8.0.87-1
ENV NV_CUDNN_PACKAGE_NAME="libcudnn9-cuda-12"
ENV NV_CUDNN_PACKAGE="libcudnn9-cuda-12=${NV_CUDNN_VERSION}"

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ${NV_CUDNN_PACKAGE} \
    && apt-mark hold ${NV_CUDNN_PACKAGE_NAME}

ARG BASE_DOCKER_FROM=nvidia/cuda:12.8.1-runtime-ubuntu24.04
