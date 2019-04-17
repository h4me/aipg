#!/bin/bash

export http_proxy="http://proxy-chain.intel.com:911"
export https_proxy="$http_proxy"

if [ ! -f /usr/bin/git ]; then
  sudo http_proxy="$http_proxy" apt-get install git
fi

USER_NAME=`whoami`
GIT_DOWNLOAD_REPOS="https://$USER_NAME@github.intel.com/AIPG/paddle https://$USER_NAME@github.intel.com/AIPG/paddle-models"
CHECK_FOLDERS="paddle paddle-models"

for repo in $GIT_DOWNLOAD_REPOS; do 
  echo "Download  $repo"
  git clone $repo
done



for d in $CHECK_FOLDERS; do 
  
    if [ ! -d $d ]; then 
      echo "Unable to download repository [$d] - directory not found"
      exit 1
    fi

done


echo "== Git repositories [OK] ==="

exit 0

