#!/bin/bash

root="/home/pawepiot/workspace/this_one/aipg/scripts/"
from="$root/ngraph-paddle/"
to="$root/paddle-public/"

list_dir="$from $to"

op_dir="paddle/fluid/operators/ngraph/ops/"
op_test="python/paddle/fluid/tests/unittests/ngraph/"
op_test_nnp="$op_test/nnp/"


#integrate_message="Enable ngraph matmul_op"
integrate_message="Enable ngraph layer norm"
file_operator="transpose_op.h"
file_test_operator="test_transpose_ngraph_op.py"
file_test_operator_nnp="test_matmul_ngraph_nnp_op.py"

from_integrate_op="$from/$op_dir/$file_operator"
from_integrate_test="$from/$op_test/$file_test_operator"
from_integrate_test_nnp="$from/$op_test_nnp/$file_test_operator_nnp"

to_integrate_op="$to/$op_dir/$file_operator"
to_integrate_test="$to/$op_test/$file_test_operator"
to_integrate_test_nnp="$to/$op_test_nnp/$file_test_operator_nnp"
path_diff="$root/mydiff.txt"

echo > $path_diff

function error() {

    echo "[ERROR]: " $1 
}

function check_if_dirs_exist()
{
for dir_ in $1; do 
  if [ ! -d $dir_ ]; then
    error "Directory does not exist $dir_"
    exit 1
  fi
done
}

function check_if_files_exist()
{
for file_ in $1; do 
  if [ ! -f $file_ ]; then
    error "File does not exist $file_"
    exit 1
  fi
done
}

function check() {

    if [ $? -ne 0 ]; then
      error $1
    fi
}


function integrate_dirs() {

     echo "########## operators ############"
     check_if_dirs_exist $list_dir

   _from_op=$1
   _to_op=$2
   # _from_op=$from/$op_dir
   # _to_op=$to/$op_dir

    files=`ls -al $_from_op | grep '^-' | awk '{print $9}'`
    for f in $files; do
      if [ ! -f "$_to_op/$f" ]; then
           echo "File is not exists so copy  $_to_op => $f"
           cp $_from_op/$f $_to_op/$f
           cd $_to_op
           git add $f
     else   
          #cmp --silent $_from_op/$f $_to_op/$f 
         
           #if [ $? -ne 0 ]; then
           
           echo "+++ Compare $f +++" >> $path_diff     
           diff $_from_op/$f $_to_op/$f  >> $path_diff

         # fi         
     fi
    done
    echo "######################"


}

function integrate_all() {

    integrate_dirs "$from/$op_dir" "$to/$op_dir"
    integrate_dirs "$from/$op_test" "$to/$op_test"
    git commit -am 'all operators - auto'
} 


function totalcopy() {

    cd $from/$op_dir
    cp * "$to/$op_dir"
    cd $to/$op_dir && git add .
    cd $from/$op_test  
    cp * "$to/$op_test"
    cd $to/$op_test && git add .

   git commit -am 'add alls'
}


function intergate_operators_nonnp()
{

   miss_files="$to_integrate_op $to_integrate_test "
   curr_files="$from_integrate_op $from_integrate_test " 


   check_if_files_exist $curr_files

    for file in $miss_files; do
      
       if [ -f $file ]; then
        error "File $file is intergated!! abort!! "
        exit 1
       fi        
    done
 
    cp $from_integrate_op $to_integrate_op
 
    if [ $? -ne 0 ]; then
      error "Can not copy file $from_integrate_op"
      exit 1
    fi

    cp $from_integrate_test $to_integrate_test
    if [ $? -ne 0 ]; then
      error "Can not copy file $from_integrate_test"
      exit 1
    fi

     

    for file in $miss_files; do
      _file_dir=$(dirname $file)
      _file_org=$(basename $file)
    
      echo "[OK]: File $file copied $_file_org"

      cd $_file_dir
      git add $_file_org

    done
 
    git commit -am "$integrate_message"
   
     if [ $? -ne 0 ]; then
      error " git commit fail"
      exit 1
     fi  
   
    git diff HEAD^! | grep +++ 

}

function intergate_operators()
{

   miss_files="$to_integrate_op $to_integrate_test $to_integrate_test_nnp"
   curr_files="$from_integrate_op $from_integrate_test $from_integrate_test_nnp" 


   check_if_files_exist $curr_files

    for file in $miss_files; do
      
       if [ -f $file ]; then
        error "File $file is intergated!! abort!! "
        exit 1
       fi        
    done
 
    cp $from_integrate_op $to_integrate_op
 
    if [ $? -ne 0 ]; then
      error "Can not copy file $from_integrate_op"
      exit 1
    fi

    cp $from_integrate_test $to_integrate_test
    if [ $? -ne 0 ]; then
      error "Can not copy file $from_integrate_test"
      exit 1
    fi


    _dir_nnp=$(dirname $to_integrate_test_nnp)
  
    if [ ! -d $_dir_nnp ]; then
         mkdir $_dir_nnp
         if [ $? -ne 0 ]; then
            error "Can not create dir $_dir_nnp"
            exit 1
         fi 
    fi
 
    cp $from_integrate_test_nnp $to_integrate_test_nnp

   if [ $? -ne 0 ]; then
      error "Can not copy file $from_integrate_test_nnp"
      exit 1
   fi    
     

    for file in $miss_files; do
      _file_dir=$(dirname $file)
      _file_org=$(basename $file)
    
      echo "[OK]: File $file copied $_file_org"

      cd $_file_dir
      git add $_file_org

    done
 
    git commit -am "$integrate_message"
   
     if [ $? -ne 0 ]; then
      error " git commit fail"
      exit 1
     fi  
   
    git diff HEAD^! | grep +++ 

}


function get_files_from_dir()
{   
    check_if_dirs_exist $1
    files=`ls -al $1 | grep '^-' | awk '{print $9}'`
    for f in $files; do 
    echo $f
    done
}

function show_operators_not_present()
{

     echo "########## operators ############"
     check_if_dirs_exist $list_dir

    _from_op=$from/$op_dir
    _to_op=$to/$op_dir

    files=`ls -al $_from_op | grep '^-' | awk '{print $9}'`
    for f in $files; do 
      if [ ! -f "$_to_op/$f" ]; then
           echo "Not found in $_to_op => $f"   
      fi
    done
    echo "######################"
    
}


function show_tests_not_present()
{

     echo "######### TESTS #############"
     check_if_dirs_exist $list_dir

    _from_op=$from/$op_test
    _to_op=$to/$op_test

    files=`ls -al $_from_op | grep '^-' | awk '{print $9}'`
    for f in $files; do 
      if [ ! -f "$_to_op/$f" ]; then
           echo "Not found in $_to_op => $f"   
      fi
    done
    echo "######## NNP ##############"

    _from_op=$from/$op_test_nnp
    _to_op=$to/$op_test_nnp

    files=`ls -al $_from_op | grep '^-' | awk '{print $9}'`
    for f in $files; do 
      if [ ! -f "$_to_op/$f" ]; then
           echo "Not found in $_to_op => $f"   
      fi
    done
    echo '############################'
    
    
}

function usage() {

  echo "--diff"
  echo "--show-operators"
  echo "--integrate"
  echo "--integrate-all-only-not-present"
  echo "--total-copy"
  exit 1
}

if [ $# -ne 1 ]; then
    usage
fi


if [ $1 = "--show-operators" ]; then
show_operators_not_present
show_tests_not_present
fi


#intergate_operators

if [ $1 = "--total-copy" ]; then
    totalcopy

fi

if [ $1 = "--integrate-all-only-not-present" ]; then
   integrate_all
fi
#check_if_dirs_exist $list_dir
if [ $1 = "--integrate" ]; then
intergate_operators_nonnp
fi
#check_if_dirs_exist $list_dir
#check_if_files_exist "/etc/passwd"
#get_files_from_dir $from
