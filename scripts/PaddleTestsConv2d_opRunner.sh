#!/bin/bash
export http_proxy="http://proxy-chain.intel.com:911"
SAVEIFS=$IFS
ROOT_DIR=`pwd`
USER_NAME=""

if [ ${#USER_NAME} == 0 ]; then

      IFS="/" tokens=($HOME)
      USER_NAME=${tokens[2]}
      IFS=$SAVEIFS   
fi

CORES="10"

GIT_DOWNLOAD_REPOS="https://$USER_NAME@github.intel.com/AIPG/paddle https://$USER_NAME@github.intel.com/AIPG/paddle-models"



#################################
######## PADDLEPADDLE CONFIG ####
#################################

PADDLE_DIR="$ROOT_DIR/paddle"
OPT_PADDLE_BUILD="$PADDLE_DIR/build"

export PYTHONPATH=$OPT_PADDLE_BUILD/python:$OPT_PADDLE_BUILD/paddle

#################################
####### MODEL CONFIG ############
#################################
MODEL_DIR="$ROOT_DIR/paddle-models"
MODEL_CAPI_DIR="$MODEL_DIR/fluid/image_classification/capi/"

OPT_MODEL_CAPI_DIR_BUILD="$MODEL_CAPI_DIR/build"

#################################
####### EXTRACT #################
#################################

#USE_MODEL="resnet50_baidu"
#USE_MODEL="MobileNet_imagenet"
USE_MODEL="MobileNet-v1_baidu"
SAVE_MODELS_DIR="$ROOT_DIR/save_models_extract_dir"

##########################
#   BIG_DATA_SET_CONFIG
##########################

BIG_DATASET_DIR_DATA="/home/$USER_NAME/BIG_DATASET/imagenet/"
BIG_DATASET_LIST_FILE="$BIG_DATASET_DIR_DATA/val_list.txt"


##########################
##### TESTS #################
LCOV_PATH="/usr/bin/lcov"

function usage() {

  echo "usage(): \n" 
  echo "--cmake"
  echo "--build"
  echo "--run"
  echo "--cgdb"
  echo "--cgdb2 [test_conv2d_mkldnn_op.py]"
  
  exit 1;

}


function FetchRepository() {
 

    for repo in $GIT_DOWNLOAD_REPOS; do 
           local git_repo="$repo"
           echo "Repository $git_repo"
           IFS="/" tokens=($repo)
           IFS=$SAVEIFS
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



    if [ ! -d "$BIG_DATASET_DIR_DATA" ]; then

        echo "[ERROR]: Diretory BIG_DATA does not exist $BIG_DATASET_DIR_DATA"
        exit;
    fi
    
    sub_folders="small val"

    for folder in $sub_folder; do 
       
     if [ ! -d "$BIG_DATASET_DIR_DATA/$folder" ]; then
            echo "[ERROR]: Big_data set is wrong $BIG_DATASET_DIR_DATA/$folder "
            exit
     fi    

    done 



    if [ ! -f "$BIG_DATASET_LIST_FILE" ]; then
        echo "[ERROR]: DataList file does not exist $BIG_DATASET_LIST_FILE"
        exit
    fi

     cd $OPT_MODEL_CAPI_DIR_BUILD
                                                                                       
      numactl --membind=0 --physcpubind=0-19 ./infer_image_classification --infer_model="$SAVE_MODELS_DIR/$USE_MODEL" --data_list=$BIG_DATASET_LIST_FILE --data_dir=$BIG_DATASET_DIR_DATA --skip_batch_num=0 --batch_size=32 --iterations=100 --profile --paddle_num_threads=20 --use_mkldnn

      cd $ROOT_DIR
}


function OptBuildCmakePaddle() {


     if [ ! -f "$LCOV_PATH" ]; then
         echo "[WARN]: LCOV not found install apt-get install auto-install "
         sudo http_proxy="$http_proxy" apt-get update && sudo http_proxy="$http_proxy"  apt-get install -y lcov
     fi

     if [ ! -f "$LCOV_PATH" ]; then
         echo "[ERROR]: LCOV not found $LCOV_PATH"
         exit
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: first you have to download repository $PADDLE_DIR"
            FetchRepository;
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: Paddle download is not complete directory not found  $PADDLE_DIR"
            exit;
     fi

     cd $ROOT_DIR
     if [ ! -d "$OPT_PADDLE_BUILD" ]; then
            mkdir $OPT_PADDLE_BUILD
     fi

     echo "Go inside $OPT_PADDLE_BUILD"  
     cd $OPT_PADDLE_BUILD
   

    cmake .. -DWITH_GPU=OFF -DWITH_PROFILER=ON -DWITH_STYLE_CHECK=OFF -DWITH_MKLDNN=ON -DWITH_TESTING=ON -DWITH_COVERAGE=ON

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : cmake ...."
        exit;
     fi
   
     echo "[SUCCESS]: ====== END OF CMAKE ========="
  
}


function OptBuild() {


     if [ ! -f "$LCOV_PATH" ]; then
         echo "[WARN]: LCOV not found install apt-get install auto-install "
         sudo http_proxy="$http_proxy" apt-get update && sudo http_proxy="$http_proxy"  apt-get install -y lcov
     fi

     if [ ! -f "$LCOV_PATH" ]; then
         echo "[ERROR]: LCOV not found $LCOV_PATH"
         exit
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: first you have to download repository $PADDLE_DIR"
            FetchRepository;
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: Paddle download is not complete directory not found  $PADDLE_DIR"
            exit;
     fi

     cd $ROOT_DIR
     if [ ! -d "$OPT_PADDLE_BUILD" ]; then
            mkdir $OPT_PADDLE_BUILD
     fi

     echo "Go inside $OPT_PADDLE_BUILD"  
     cd $OPT_PADDLE_BUILD
   

   # cmake .. -DWITH_GPU=OFF -DWITH_PROFILER=ON -DWITH_STYLE_CHECK=OFF -DWITH_MKLDNN=ON -DWITH_TESTING=ON -DWITH_COVERAGE=ON

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : cmake ...."
        exit;
     fi

    make -j $CORES

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : make -j $CORES"
        exit;
    fi

   
   echo "[SUCCESS]: ====== BUILD SUCCESS ========="
  
}




function OptRunTest() {


     if [ ! -f "$LCOV_PATH" ]; then
         echo "[WARN]: LCOV not found install apt-get install auto-install "
         sudo http_proxy="$http_proxy" apt-get update && sudo http_proxy="$http_proxy"  apt-get install -y lcov
     fi

     if [ ! -f "$LCOV_PATH" ]; then
         echo "[ERROR]: LCOV not found $LCOV_PATH"
         exit
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: first you have to download repository $PADDLE_DIR"
            FetchRepository;
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: Paddle download is not complete directory not found  $PADDLE_DIR"
            exit;
     fi

     cd $ROOT_DIR
     if [ ! -d "$OPT_PADDLE_BUILD" ]; then
            mkdir $OPT_PADDLE_BUILD
     fi

     echo "Go inside $OPT_PADDLE_BUILD"  
     cd $OPT_PADDLE_BUILD
   

   # cmake .. -DWITH_GPU=OFF -DWITH_PROFILER=ON -DWITH_STYLE_CHECK=OFF -DWITH_MKLDNN=ON -DWITH_TESTING=ON -DWITH_COVERAGE=ON

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : cmake ...."
        exit;
     fi

   # make -j $CORES

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : make -j $CORES"
        exit;
    fi

   # ctest -R -V 

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : ctest -R"
        exit;
    fi

    #ctest -R mkldnn
    #ctest -R mkldnn -V

    #ctest -R conv2d_op -V
    ctest -R $1 -V
#    $LCOV_PATH --capture --directory . --output-file coverage.info
   # genhtml --demangle-cpp coverage.info --output-directory out
    echo "$PYTHONPATH"

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : LCOV "
        exit;
    fi

   echo "[SUCCESS]: ====== TEST OK ========="
  
}






function RunTests() {


     if [ ! -f "$LCOV_PATH" ]; then
         echo "[WARN]: LCOV not found install apt-get install auto-install "
         sudo http_proxy="$http_proxy" apt-get update && sudo http_proxy="$http_proxy"  apt-get install -y lcov
     fi

     if [ ! -f "$LCOV_PATH" ]; then
         echo "[ERROR]: LCOV not found $LCOV_PATH"
         exit
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: first you have to download repository $PADDLE_DIR"
            FetchRepository;
     fi
    
     if [ ! -d "$PADDLE_DIR" ]; then
            echo "[ERROR]: Paddle download is not complete directory not found  $PADDLE_DIR"
            exit;
     fi

     cd $ROOT_DIR
     if [ ! -d "$OPT_PADDLE_BUILD" ]; then
            mkdir $OPT_PADDLE_BUILD
     fi

     echo "Go inside $OPT_PADDLE_BUILD"  
     cd $OPT_PADDLE_BUILD
   

   # cmake .. -DWITH_GPU=OFF -DWITH_PROFILER=ON -DWITH_STYLE_CHECK=OFF -DWITH_MKLDNN=ON -DWITH_TESTING=ON -DWITH_COVERAGE=ON

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : cmake ...."
        exit;
     fi

   # make -j $CORES

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : make -j $CORES"
        exit;
    fi

   # ctest -R -V 

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : ctest -R"
        exit;
    fi

    #ctest -R mkldnn
    #ctest -R mkldnn -V

    ctest -R conv2d_op -V
#    $LCOV_PATH --capture --directory . --output-file coverage.info
   # genhtml --demangle-cpp coverage.info --output-directory out
 echo "$PYTHONPATH"

    if [ ! $? -eq 0 ]; then
        echo "[ERROR] : LCOV "
        exit;
    fi

   echo "[SUCCESS]: ====== END OF TESTS ========="
  
}


function OptCgdbAttach() {

  echo "Attach to cgdb......$1"
  export PYTHONPATH="$PYTHONPATH"

  unit_test_dir="$PADDLE_DIR/build/python/paddle/fluid/tests/unittests/"

  if [ ! -d $unit_test_dir ]; then 

    echo "error: Directory does not exist $unit_test_dir"
    exit 1
  fi

  cd $unit_test_dir

  # FLAGS_use_mkldnn=true cgdb python --args python2.7 __test_name__
  # export FLAGS_use_mkldnn=true
   FLAGS_use_mkldnn=true cgdb python --args python2.7 test_$1.py

}


function OptCgdbAttach2() {

  echo "Attach to cgdb......$1"
  export PYTHONPATH="$PYTHONPATH"

  unit_test_dir="$PADDLE_DIR/build/python/paddle/fluid/tests/unittests/mkldnn/"

  if [ ! -d $unit_test_dir ]; then 

    echo "error: Directory does not exist $unit_test_dir"
    exit 1
  fi

  cd $unit_test_dir

  # FLAGS_use_mkldnn=true cgdb python --args python2.7 __test_name__
   export FLAGS_use_mkldnn=true
   FLAGS_use_mkldnn=true cgdb  --args python2.7 test_conv2d_mkldnn_op.py

}



function run_all() {

   RunTests
   
}

#var used=0

 if [ $# -eq 0 ]; then
    usage
 fi 

for item in "$@"
do
     used=0
    if [  "$item" = "--cmake" ]; then
           echo "--cmake found"
           OptBuildCmakePaddle
           used=1 
    fi  
    

    if [  "$item" = "--build" ]; then
           echo "--build found";
           OptBuild
           used=1 
    fi  
    

    if [  "$item" = "--run" ]; then
           echo "--run found";
           OptRunTest "conv2d_op"
           used=1 
    fi  
   

    if [  "$item" = "--cgdb" ]; then
           echo "--run found";
           OptCgdbAttach "conv2d_op"
           used=1 
    fi  
   

    if [  "$item" = "--cgdb2" ]; then
           echo "--run found";
           OptCgdbAttach2 "conv2d_op"
           used=1 
    fi  
   
    
   
    
   
  #    OptRunTest("conv2d_op")
    
    if [ $used = 0 ]; then
       usage
    fi
     

done

#run_all

#case "$1" in

   #"1") BuildPaddlePaddle ;;
   #"2") build_capi_model ;;
   #"3") run_infer_image ;;
   #"4") RunTests ;;

 #  *)  run_all
        
#esac

