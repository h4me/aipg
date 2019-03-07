#!/bin/bash

ROOT_DIR=`pwd`
USER_NAME=""

if [ ${#USER_NAME} == 0 ]; then

      IFS="/" tokens=($HOME)
      IFS=""
      USER_NAME=${tokens[2]}   
fi


CORES="12"
GIT_DOWNLOAD_REPOS="https://$USER_NAME@github.intel.com/AIPG/paddle https://$USER_NAME@github.intel.com/AIPG/paddle-models"



#################################
######## PADDLEPADDLE CONFIG ####
#################################

PADDLE_DIR="$ROOT_DIR/paddle"
OPT_PADDLE_BUILD="$PADDLE_DIR/build"

#################################
####### MODEL CONFIG ############
#################################
MODEL_DIR="$ROOT_DIR/paddle-models"
MODEL_CAPI_DIR="$MODEL_DIR/fluid/image_classification/capi/"

OPT_MODEL_CAPI_DIR_BUILD="$MODEL_CAPI_DIR/build"

#################################
####### EXTRACT #################
#################################

USE_MODEL="resnet50_baidu"
SAVE_MODELS_DIR="$ROOT_DIR/save_models_extract_dir"



function FetchRepository() {
 

    for repo in $GIT_DOWNLOAD_REPOS; do 
           local git_repo="$repo"
           echo "Repository $git_repo"
           IFS="/" tokens=($repo)
           IFS=""
           last=${#tokens[@]}
           repo_dir=${tokens[$last-1]}
           echo "Check if $repo_dir exists...."
           if [ ! -d "$repo_dir" ]; then
               echo "Download Repository  $repo"
               git clone $repo                          
            fi
    done
     


}


function BuildPaddlePaddle() {
     
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "ERROR: first you have to download repository $PADDLE_DIR"
            FetchRepository;
     fi
   
     cd $ROOT_DIR
     if [ ! -d "$OPT_PADDLE_BUILD" ]; then
            mkdir $OPT_PADDLE_BUILD
     fi

     echo "Go inside $OPT_PADDLE_BUILD"  
     cd $OPT_PADDLE_BUILD
     
     cmake .. -DWITH_GPU=OFF -DWITH_PROFILER=ON -DWITH_STYLE_CHECK=OFF -DWITH_MKLDNN=ON -DWITH_FLUID_ONLY=ON -DWITH_TESTING=OFF
     make -j $CORES ;make -j $CORES  inference_lib_dist


}


function build_capi_model() {

     if [ ! -d "$MODEL_DIR" ]; then
            echo "ERROR: first you have to download repository $MODEL_DIR"
            FetchRepository;
     fi

     if [ ! -d "$MODEL_CAPI_DIR" ]; then
         cd $MODEL_DIR
         git checkout develop-integration
     fi
       
     if [ ! -d "$OPT_MODEL_CAPI_DIR_BUILD" ]; then
            mkdir $OPT_MODEL_CAPI_DIR_BUILD
     fi

     cd $OPT_MODEL_CAPI_DIR_BUILD
     cmake .. -DPADDLE_ROOT=$OPT_PADDLE_BUILD/fluid_install_dir/;make -j $CORES


}


function run_infer_image() {

     if [ ! -d "$MODEL_DIR" ]; then
         echo "[ERROR]: Fist you need build paddle-model"
         exit
     fi


     if [ ! -d "$PADDLE_DIR" ]; then
         echo "[ERROR]: Fist you need build paddle-paddle"
         exit
     fi

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

     cd $OPT_MODEL_CAPI_DIR_BUILD
     ./infer_image_classification --infer_model="$SAVE_MODELS_DIR/$USE_MODEL" --use_fake_data --skip_batch_num=10 --batch_size=128 --iterations=100 --profile --paddle_num_threads=20 --use_mkldnn
     cd $ROOT_DIR
}


function run_all() {

    BuildPaddlePaddle;
    build_capi_model;
    run_infer_image;

}


case "$1" in

   "1") BuildPaddlePaddle ;;
   "2") build_capi_model ;;
   "3") run_infer_image ;;

   *)  run_all
        
esac

