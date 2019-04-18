#!/bin/bash

export http_proxy="http://proxy-chain.intel.com:911"
export https_proxy="$http_proxy"

if [ ! -f /usr/bin/git ]; then
  sudo http_proxy="$http_proxy" apt-get install git
fi

USER_NAME=`whoami`
GIT_DOWNLOAD_REPOS="https://$USER_NAME@github.intel.com/AIPG/paddle-models"

NEWNAME="paddle-public"
CHECK_FOLDERS="$NEWNAME paddle-models"

for repo in $GIT_DOWNLOAD_REPOS; do 
  echo "Download  $repo"
  git clone -b develop-integration $repo
done


git clone https://github.com/PaddlePaddle/Paddle.git $NEWNAME

for d in $CHECK_FOLDERS; do 
  
    if [ ! -d $d ]; then 
      echo "Unable to download repository [$d] - directory not found"
      exit 1
    fi

done


echo "== Git repositories [OK] ==="

echo "export PADDLE_REF=\"$NEWNAME\" " > ref.txt
exit 0

