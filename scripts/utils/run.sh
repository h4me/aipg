#!/bin/bash

#cd paddle-public/build

main=`pwd`
workspaceFolder="$main/paddle-public"

cd paddle-public/build
cmd_ok="${workspaceFolder}/build/paddle/fluid/inference/tests/api/test_analyzer_image_classification --infer_model=${workspaceFolder}/build/third_party/inference_demo/googlenet/model --gtest_filter=Analyzer_resnet50.profile --use_ngraph --use_analysis=false --repeat=100 --paddle_num_threads=4 "
#cmd_ok="./paddle/fluid/inference/tests/api/test_analyzer_bert  --infer_model=./third_party/inference_demo/googlenet/model --gtest_filter=Analyzer_bert.profile --use_ngraph --use_analysis=false --repeat=100 --paddle_num_threads=4" 
#cmd_ok="cgdb --args ./paddle/fluid/inference/tests/api/test_analyzer_googlenet --infer_model=./third_party/inference_demo/googlenet/model --gtest_filter=Analyzer_resnet50.profile --use_ngraph --use_analysis=false --repeat=100 --paddle_num_threads=4" 
#cmd_ok="/usr/bin/cgdb --args ./paddle/fluid/inference/tests/api/test_analyzer_googlenet --infer_model=./third_party/inference_demo/googlenet/model --gtest_filter=Analyzer_resnet50.profile --use_ngraph --use_analysis=false --repeat=100 --paddle_num_threads=4" 

cmd_fail="$cmd_ok --num_threads=4"
if [ $1 = "--fail" ]; then

echo "**** FAIL **** "

 $cmd_fail
  
else
echo "**** PLAIN **** "

 $cmd_ok

fi
