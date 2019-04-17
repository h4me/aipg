#!/bin/bash
ulimit -n 65535

if [ ! -f ref.txt ]; then
   echo "ref.txt not found run pre script"
   exit 1
fi


source ref.txt


echo $PADDLE_REF

ROOT_DIR=`pwd`
MODEL_DIR="$ROOT_DIR/paddle-models"
build_dir_release="$ROOT_DIR/$PADDLE_REF/build_release"
build_dir_debug="$ROOT_DIR/$PADDLE_REF/build_debug"

IIC_SCRIPT_DIR="paddle-models/fluid/image_classification/"
IIC_SCRIPT="$IIC_SCRIPT_DIR/infer_image_classification.py"

USE_MODEL="resnet50_baidu"
#USE_MODEL="MobileNet_imagenet"
#USE_MODEL="MobileNet-v1_baidu"
SAVE_MODELS_DIR="$ROOT_DIR/save_models_extract_dir"


OPT_PADDLE_BUILD_DEBUG="$build_dir_debug/python:$build_dir_debug/paddle"
OPT_PADDLE_BUILD_RELEASE="$build_dir_release/python:$build_dir_release/paddle"

function build_release()
{

    echo "******* BUILD RELEASE *****"
    
   
    if [ ! -d $build_dir_release ]; then
         echo "Create directory $build_dir_release"
         mkdir $build_dir_release 
    fi

    cd $build_dir_release

    cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_DOC=OFF -DWITH_GPU=OFF -DWITH_DISTRIBUTE=OFF -DWITH_MKLDNN=ON -DWITH_MKL=ON -DWITH_GOLANG=OFF -DWITH_STYLE_CHECK=OFF -DWITH_TESTING=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DWITH_PROFILER=OFF -DWITH_NGRAPH=ON

      make -j50


}

function build_debug()
{

    echo "******* BUILD Debug *****"


    if [ ! -d $build_dir_debug ]; then
         echo "Create directory $build_dir_debug"
         mkdir $build_dir_debug
    fi

    cd $build_dir_debug

    cmake .. -DCMAKE_BUILD_TYPE=Debug -DWITH_DOC=OFF -DWITH_GPU=OFF -DWITH_DISTRIBUTE=OFF -DWITH_MKLDNN=ON -DWITH_MKL=ON -DWITH_GOLANG=OFF -DWITH_STYLE_CHECK=OFF -DWITH_TESTING=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DWITH_PROFILER=OFF -DWITH_NGRAPH=ON

      make -j50



}



function prepare_model()
{

   if [ ! -d "$SAVE_MODELS_DIR" ]; then
              mkdir $SAVE_MODELS_DIR
     fi

     if [ ! -d "$SAVE_MODELS_DIR/$USE_MODEL" ]; then

          MODEL_FILE="$MODEL_DIR/fluid/image_classification/saved_models/$USE_MODEL.tar.gz"
          if [ ! -f "$MODEL_FILE" ]; then
               echo "Can not find model file $MODEL_FILE"
               exit
          fi

          tar -zxvf $MODEL_FILE -C $SAVE_MODELS_DIR

     fi


}



function infer_image_debug() {


    echo "**** RUN INFER IMAGE *****"

    if [ ! -f $IIC_SCRIPT ]; then
        echo "FILE $IIC_SCIRPT not found"
       exit 1
    fi

    prepare_model
     
    export PYTHONPATH="$OPT_PADDLE_BUILD_DEBUG"

    echo "PYTHONPATH=$PYTHONPATH"

    cd $IIC_SCRIPT_DIR 
  #  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path=/data/PaddlePaddle/models/paddlepaddle/resnet_50_v1 --profile --use_fake_data
    python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path="$SAVE_MODELS_DIR/$USE_MODEL" --profile --use_fake_data


}

function infer_image_release() {


    echo "**** RUN INFER IMAGE *****"

    if [ ! -f $IIC_SCRIPT ]; then
        echo "FILE $IIC_SCIRPT not found"
       exit 1
    fi

    prepare_model

    export PYTHONPATH="$OPT_PADDLE_BUILD_RELEASE"

    echo "PYTHONPATH=$PYTHONPATH"

    cd $IIC_SCRIPT_DIR
  #  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path=/data/PaddlePaddle/models/paddlepaddle/resnet_50_v1 --profile --use_fake_data

    FLAGS_use_ngraph=true FLAGS_use_ngraph_cache=true  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path="$SAVE_MODELS_DIR/$USE_MODEL" --profile --use_fake_data


}




#build_release
#build_debug
#infer_image_debug
infer_image_release

