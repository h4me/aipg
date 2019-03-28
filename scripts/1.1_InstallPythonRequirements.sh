#!/bin/bash

export http_proxy="http://proxy-chain.intel.com:911"
export https_proxy="$http_proxy"

req_file="requirements.txt"


if [ ! -d paddle ]; then
  echo "error: First download paddle repo "
  exit 1
fi


cd paddle/python

sudo -H http_proxy="$http_proxy" pip --proxy $http_proxy install -r $req_file 


exit 0
