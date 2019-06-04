#!/bin/bash
ulimit -n 65535
CORES="50"
is_debug=0
is_cmake=0
is_build=0
is_infer_python=0
is_build_capi_app_infer_image=0
is_build_capi=0
is_infer_capi=0
is_build_paddlepaddle=0
is_ctest=0
is_clear=0

if [ ! -f ref.txt ]; then
   echo "ref.txt not found run pre script"
   exit 1
fi

#declare -A options

#options["input"]="runner"

#${options["input"]}


ROOT_DIR=`pwd`
log="$ROOT_DIR/commands.txt"

echo > $log

function exe_cmd() {

   echo -e '\033[0;31m'  $1  '\033[0m'
   echo $1 >> $log

   $1

   if [ $? -ne 0 ]; then
      echo "FAIL on $1" >> $log
   fi

}

function exe_note() {

    echo "[note]:  $1" >> $log

}   



#exe_cmd "ls -l"

#exit 1


source ref.txt

echo -e '\033[0;31m'"########## WORKDIR: ["  $PADDLE_REF "] ####################"  '\033[0m'
function usage() {

     echo "Usage:  [--show-python-path]"
     echo "Usage:  [--debug] --clear {--build-paddlepaddle --build-paddlepaddle-only-make } --build-capi-app-infer-image --run-infer-capi --run-infer-python"
     echo "---- python unit test ---"
     echo "Usage:  [--ctest-stack]"
     echo "Usage:  [--ctest-exe] [test_name] for instnace {test_reduce_ngraph_op}"
}


function note() {

echo -e '\033[0;31m'"[info]:"$1'\033[0m'

}



MODEL_DIR="$ROOT_DIR/ngraph-models"
MODEL_CAPI_DIR="$MODEL_DIR/fluid/image_classification/capi/"
#OPT_MODEL_CAPI_DIR_BUILD="$MODEL_CAPI_DIR/build"
OPT_MODEL_CAPI_DIR_BUILD=""



build_dir_release="$ROOT_DIR/$PADDLE_REF/build_release"
build_dir_debug="$ROOT_DIR/$PADDLE_REF/build_debug"
build_dir_paddlepaddle=""

IIC_SCRIPT_DIR="$ROOT_DIR/paddle-models/fluid/image_classification/"
IIC_SCRIPT="$IIC_SCRIPT_DIR/infer_image_classification.py"

USE_MODEL="resnet50_baidu"
#USE_MODEL="MobileNet_imagenet"
#USE_MODEL="MobileNet-v1_baidu"
SAVE_MODELS_DIR="$ROOT_DIR/save_models_extract_dir"


OPT_PADDLE_BUILD_DEBUG="$build_dir_debug/python:$build_dir_debug/paddle"
OPT_PADDLE_BUILD_RELEASE="$build_dir_release/python:$build_dir_release/paddle"


##########################
#   BIG_DATA_SET_CONFIG
##########################

BIG_DATASET_DIR_DATA="/home/pawepiot/BIG_DATASET/imagenet/"
BIG_DATASET_LIST_FILE="$BIG_DATASET_DIR_DATA/val_list.txt"


function run_ctest() {

  test_name=$1

  if [ ! -d $build_dir_paddlepaddle ]; then
   echo "ERROR: first build paddle paddle not dir found $build_dir_paddlepaddle"
   exit 1
  fi

  exe_cmd "cd $build_dir_paddlepaddle"

 # if [ $is_debug -eq 1 ]; then
   
#  fi

  export LD_LIBRARY_PATH="$build_dir_debug/python/paddle/libs"  
  note "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
  exe_note "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

  if [ ! -d $LD_LIBRARY_PATH ]; then
    echo "ERROR: fail set LD_LIBRARY_PATH dir not found $LD_LIBRARY_PATH"
    exit 1
  fi

  #export FLAGS_use_ngraph=true
  exe_cmd "ctest -R $test_name -V"
  

}

function build_capi_app_infer_image()
{
   
     if [ ! -d "$MODEL_DIR" ]; then
            echo "ERROR: first you have to download repository $MODEL_DIR"
            exit 1
     fi

    
      if [ ! -d "$MODEL_CAPI_DIR" ]; then
         exe_cmd "cd $MODEL_DIR"
         exe_cmd "git checkout develop-integration"
       fi
    


     if [ ! -d "$OPT_MODEL_CAPI_DIR_BUILD" ]; then
            exe_cmd "mkdir $OPT_MODEL_CAPI_DIR_BUILD"
     fi
    
    
     exe_cmd "cd $OPT_MODEL_CAPI_DIR_BUILD"
 
    OPT_PADDLE_BUILD=$build_dir_release
    TYPE_COMPILE=" "

    if [ $is_debug -eq 1 ]; then
       TYPE_COMPILE="-DCMAKE_BUILD_TYPE=Debug"
       OPT_PADDLE_BUILD=$build_dir_debug
   
    fi

      
    if [ ! -d "$OPT_PADDLE_BUILD/fluid_install_dir/" ]; then
       echo "Error: paddle build does not exist ... fluid_install_dir" 
       exit 1
    fi

    exe_cmd "cmake .. $TYPE_COMPILE -DPADDLE_ROOT=$OPT_PADDLE_BUILD/fluid_install_dir/"
    exe_cmd "make -j $CORES"



}



function build_capi()
{

     if [ ! -d "$MODEL_DIR" ]; then
            echo "ERROR: first you have to download repository $MODEL_DIR"
            exit 1
     fi

     if [ ! -d "$MODEL_CAPI_DIR" ]; then
         exe_cmd "cd $MODEL_DIR"
         exe_cmd "git checkout develop-integration"
     fi
    

     if [ ! -d "$OPT_MODEL_CAPI_DIR_BUILD" ]; then
            exe_cmd "mkdir $OPT_MODEL_CAPI_DIR_BUILD"
     fi
    
    
    exe_cmd "cd $OPT_MODEL_CAPI_DIR_BUILD"
    

    OPT_PADDLE_BUILD=$build_dir_release
    TYPE_COMPILE=" "

    if [ $is_debug -eq 1 ]; then
       TYPE_COMPILE="-DCMAKE_BUILD_TYPE=Debug"
       OPT_PADDLE_BUILD=$build_dir_debug
   
    fi

  

    exe_cmd "cmake .. $TYPE_COMPILE -DPADDLE_ROOT=$OPT_PADDLE_BUILD/fluid_install_dir/"
   
   # cmake .. -DCMAKE_BUILD_TYPE=$TYPE_COMPILE -DPADDLE_ROOT=$OPT_PADDLE_BUILD/fluid_install_dir/

    exe_cmd "make -j $CORES"    
   # make -j $CORES

}



function run_infer_capi() 
{


    if [ ! -f "$BIG_DATASET_LIST_FILE" ]; then
        echo "[ERROR]: DataList file does not exist $BIG_DATASET_LIST_FILE"
        exit
    fi

     if [ $is_debug -eq 0 ]; then
          
          export LD_LIBRARY_PATH="$build_dir_debug/python/paddle/libs" 
         # echo "LIBKI: $LD_LIBRARY_PATH"
         exe_note "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
     fi
     
    export FLAGS_use_ngraph=true
    exe_note "export FLAGS_use_ngraph=true" 

    export FLAGS_use_ngraph_cache=true
    exe_note "export FLAGS_use_ngraph_cache=true"  
      
    exe_cmd "cd $OPT_MODEL_CAPI_DIR_BUILD"
                                                                                       
    exe_cmd "numactl --membind=0 --physcpubind=0-19 ./infer_image_classification --infer_model="$SAVE_MODELS_DIR/$USE_MODEL" --data_list=$BIG_DATASET_LIST_FILE --data_dir=$BIG_DATASET_DIR_DATA --skip_batch_num=0 --batch_size=32 --iterations=100 --profile --paddle_num_threads=20 --use_mkldnn"

    cd $ROOT_DIR


}


function build_paddlepaddle()
{

        if [ ! -d $build_dir_paddlepaddle ]; then
           echo "Create directory $build_dir_paddlepaddle"
           exe_cmd "mkdir $build_dir_paddlepaddle" 
        fi
        
        exe_cmd "cd $build_dir_paddlepaddle"

 
     TYPE_COMPILE=" "
 #   TYPE_COMPILE="RelWithDebInfo"
  #  TYPE_COMPILE="Release"

    if [ $is_debug -eq 1 ]; then
       TYPE_COMPILE="-DCMAKE_BUILD_TYPE=Debug"
    fi

    extra_options=""

    extra="-DWITH_TESTING=OFF -DWITH_INFERENCE_API_TEST=ON -DON_INFER=ON -DWITH_PYTHON=ON"
    extra_options="$extra -DWITH_NGRAPH=ON "

   if [ $1 -eq 1 ]; then
      exe_cmd "cmake .. $TYPE_COMPILE $extra_options  -DWITH_GPU=OFF "
   fi
   
    exe_cmd "make -j $CORES"
    exe_cmd "make -j $CORES  inference_lib_dist"



}



function prepare_model()
{

   if [ ! -d "$SAVE_MODELS_DIR" ]; then
             exe_cmd "mkdir $SAVE_MODELS_DIR"
     fi

     if [ ! -d "$SAVE_MODELS_DIR/$USE_MODEL" ]; then

          MODEL_FILE="$MODEL_DIR/fluid/image_classification/saved_models/$USE_MODEL.tar.gz"
          if [ ! -f "$MODEL_FILE" ]; then
               echo "Can not find model file $MODEL_FILE"
               exit
          fi

          exe_cmd "tar -zxvf $MODEL_FILE -C $SAVE_MODELS_DIR"

     fi


}


function showpythonpath() {


    echo "****SHOW_PYTHON_PATH *****"

#    if [ ! -f $IIC_SCRIPT ]; then
#        echo "FILE $IIC_SCIRPT not found"
#       exit 1
#    fi

   # prepare_model
     
    export PYTHONPATH="$OPT_PADDLE_BUILD_DEBUG"

    echo "PYTHONPATH=$PYTHONPATH"

    #cd $IIC_SCRIPT_DIR 
  #  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path=/data/PaddlePaddle/models/paddlepaddle/resnet_50_v1 --profile --use_fake_data
   # python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path="$SAVE_MODELS_DIR/$USE_MODEL" --profile --use_fake_data


}



function run_infer_image_python() {


    echo "**** RUN INFER IMAGE *****"

    if [ ! -f $IIC_SCRIPT ]; then
        echo "FILE $IIC_SCIRPT not found"
       exit 1
    fi

    prepare_model

    if [ $is_debug -eq 1 ]; then 
       export PYTHONPATH="$OPT_PADDLE_BUILD_DEBUG"
    else
       export PYTHONPATH="$OPT_PADDLE_BUILD_RELEASE"
      
       # fix for ../libs/libcpu_backend.so: undefined symbol: _ZN3tbb8internal17itt_task_begin_v7ENS0_15itt
       export LD_LIBRARY_PATH="$build_dir_debug/python/paddle/libs"   
       echo "LIBKI: $LD_LIBRARY_PATH"
    fi
    
    echo "PYTHONPATH=$PYTHONPATH"

    exe_cmd "cd $IIC_SCRIPT_DIR" 
  #  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path=/data/PaddlePaddle/models/paddlepaddle/resnet_50_v1 --profile --use_fake_data

    export FLAGS_use_ngraph=true
    export FLAGS_use_ngraph_cache=true
 
    ccmd="python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path="$SAVE_MODELS_DIR/$USE_MODEL" --profile --use_fake_data"
    $ccmd

    
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
    exe_note "export PYTHONPATH=$PYTHONPATH"

    cd $IIC_SCRIPT_DIR 
  #  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path=/data/PaddlePaddle/models/paddlepaddle/resnet_50_v1 --profile --use_fake_data
    export FLAGS_use_ngraph=true
    exe_note "export FLAGS_use_ngraph=true"

    export FLAGS_use_ngraph_cache=true
    exe_note "export FLAGS_use_ngraph_cache=true"

 ccmd="python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path="$SAVE_MODELS_DIR/$USE_MODEL" --profile --use_fake_data"
 $ccmd

 echo $ccmd 

}

function infer_image_release() {


    echo "**** RUN INFER IMAGE *****"

    if [ ! -f $IIC_SCRIPT ]; then
        echo "FILE $IIC_SCIRPT not found"
       exit 1
    fi

    prepare_model

    export PYTHONPATH="$OPT_PADDLE_BUILD_RELEASE"
    exe_note "export PYTHONPATH=$PYTHONPATH"
    export LD_LIBRARY_PATH="$build_dir_debug/python/paddle/libs"    
    echo "PYTHONPATH=$PYTHONPATH"
    exe_note "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

    exe_cmd "cd $IIC_SCRIPT_DIR"
  #  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path=/data/PaddlePaddle/models/paddlepaddle/resnet_50_v1 --profile --use_fake_data

    FLAGS_use_ngraph=true FLAGS_use_ngraph_cache=true  python infer_image_classification.py --batch_size=1 --data_set=imagenet --iterations=400 --device=CPU --skip_batch_num=10 --infer_model_path="$SAVE_MODELS_DIR/$USE_MODEL" --profile --use_fake_data

}


if [ $# -eq 0 ]; then
    usage
 fi 

is_dedicated_test=0

if [ $# -eq 2 ]; then
 
  if [ "$1" = "--ctest-exe" ]; then
     is_dedicated_test=1
  fi

fi

if [ $is_dedicated_test -eq 0 ]; then  

for item in "$@"
do
    was_used=0

      
   if [  "$item" = "--show-python-path" ]; then
           echo ""
           showpythonpath           
           exit 0
   fi


   if [  "$item" = "--clear" ]; then
           is_clear=1
           was_used=1 
   fi
  

   if [  "$item" = "--debug" ]; then
           echo "--debug found"
           is_debug=1
           was_used=1 
   fi
  

   if [  "$item" = "--run-infer-python" ]; then
           echo "----run-infer-python found"
           is_infer_python=1 
           was_used=1
   fi


   if [  "$item" = "--run-infer-capi" ]; then
           echo "----run-infer-capi found"
           is_infer_capi=1 
           was_used=1
   fi
   

   if [ "$item" = "--build-capi-app-infer-image" ]; then
         is_build_capi_app_infer_image=1
         was_used=1
   fi



   if [ "$item" = "--build-paddlepaddle" ]; then
         is_build_paddlepaddle=1
         was_used=1
   fi

   if [ "$item" = "--build-paddlepaddle-only-make" ]; then
         is_build_paddlepaddle=2
         was_used=1
   fi


   if [ "$item" = "--ctest-stack" ]; then
         is_ctest=1
         was_used=1
   fi


   if [ $was_used -eq 0 ]; then
       "ERROR Args is unknown $item" 
     exit 1
   fi


done


fi


#is_debug=0
#is_cmake=0
#is_build=0
#is_infer_python=0

if [ $is_debug -eq 1 ]; then
   OPT_MODEL_CAPI_DIR_BUILD="$MODEL_CAPI_DIR/build_debug"
   build_dir_paddlepaddle=$build_dir_debug
else
   OPT_MODEL_CAPI_DIR_BUILD="$MODEL_CAPI_DIR/build_release"
   build_dir_paddlepaddle=$build_dir_release
fi


if [ $is_clear -eq 1 ]; then
     
     note "*** TRY TO REMOVE DIRECTORY $build_dir_paddlepaddle *******"

     if [ -d $build_dir_paddlepaddle ]; then
           exe_cmd "rm -rf $build_dir_paddlepaddle"
           note "OK COMPLETE!"
     else
           note "Nothing to remove!"
     fi 

fi



if [ $is_build_paddlepaddle -gt 0 ]; then
     build_paddlepaddle $is_build_paddlepaddle 
fi

if [ $is_build_capi_app_infer_image -eq 1 ]; then
     build_capi_app_infer_image
fi


if [ $is_infer_capi -eq 1 ]; then
     run_infer_capi
fi


if [ $is_infer_python -eq 1 ]; then
        run_infer_image_python
fi


if [ $is_ctest -eq 1 ]; then

  #   run_ctest test_conv2d
   run_ctest stack_ngraph
  # run_ctest stack_op

fi


if [ $is_dedicated_test -eq 1 ]; then
    note "Run test $2" 
    run_ctest $2
fi
