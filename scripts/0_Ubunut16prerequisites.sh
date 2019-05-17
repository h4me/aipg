#!/bin/bash

export http_proxy="http://proxy-chain.intel.com:911"
export https_proxy="$http_proxy"
EXTRA="conky"

EXTRA_PKG_COMMIT="clang-format"
PKG_LIST="$EXTRA_PKG_COMMIT numactl git cmake python3-pip python-pip linux-tools-common linux-tools-4.15.0-29-generic gperf  libgoogle-perftools-dev patchelf libopencv-dev python-opencv cgdb"


sudo http_proxy="$http_proxy" apt-get update 

for p in $PKG_LIST; do 
  echo "Try to install [$p]"
  sudo http_proxy="$http_proxy" apt-get install -y $p
done


exit 0
