FROM nvidia/cuda:12.3.2-runtime-ubuntu22.04

# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.3.2/ubuntu2204/runtime/cudnn9/Dockerfile
ENV NV_CUDNN_VERSION=9.0.0.312
ENV NV_CUDNN_PACKAGE_NAME="libcudnn9-cuda-12"
ENV NV_CUDNN_PACKAGE "libcudnn9-cuda-12=${NV_CUDNN_VERSION}-1"

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ${NV_CUDNN_PACKAGE} \
    && apt-mark hold ${NV_CUDNN_PACKAGE_NAME} \
    && rm -rf /var/lib/apt/lists/*

ARG BASE_DOCKER_FROM=nvidia/cuda:12.3.2-runtime-ubuntu22.04

