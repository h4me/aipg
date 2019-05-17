#!/bin/bash

export http_proxy="http://proxy-chain.intel.com:911"
export https_proxy="$http_proxy"

req_file="requirements.txt"

source ref.txt

if [ ! -d $PADDLE_REF ]; then
  echo "error: First download paddle repo "
  exit 1
fi


cd $PADDLE_REF/python

sudo -H http_proxy="$http_proxy" pip --proxy $http_proxy install -r $req_file 

# To commit 

PKG_LIST="cpplint pylint pre-commit"

for item in $PKG_LIST; do

sudo -H http_proxy="$http_proxy" pip --proxy $http_proxy install $item 

done


exit 0
