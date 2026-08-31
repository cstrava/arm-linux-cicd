FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gcc-arm-linux-gnueabihf \
        make \
        clang-format \
        cppcheck \
        file && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace