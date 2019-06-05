# Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

add_library(ngraph INTERFACE)

IF(WIN32 OR APPLE)
    MESSAGE(WARNING
        "Windows or Mac is not supported with nGraph in Paddle yet."
        "Force WITH_NGRAPH=OFF")
    SET(WITH_NGRAPH OFF CACHE STRING "Disable nGraph in Windows and MacOS" FORCE)
ENDIF()

IF(${WITH_NGRAPH} AND NOT ${WITH_MKLDNN})
    MESSAGE(WARNING
        "nGraph needs mkl-dnn to be enabled."
        "Force WITH_NGRAPH=OFF")
    SET(WITH_NGRAPH OFF CACHE STRING "Disable nGraph if mkl-dnn is disabled" FORCE)
ENDIF()

IF(NOT ${WITH_NGRAPH})
    return()
ENDIF()

INCLUDE(GNUInstallDirs)

INCLUDE(ExternalProject)

IF(${WITH_DISTRIBUTE})
    SET(NGRAPH_DISTRIBUTED_ENABLE     "OMPI")
ENDIF()
SET(NGRAPH_PROJECT         "extern_ngraph")
#SET(NGRAPH_GIT_TAG         "v0.20.0-dev.0")
SET(NGRAPH_GIT_TAG         "pablo_v20")
SET(NGRAPH_SOURCES_DIR     ${THIRD_PARTY_PATH}/ngraph)
SET(NGRAPH_INSTALL_DIR     ${THIRD_PARTY_PATH}/install/ngraph)
SET(NGRAPH_INC_DIR         ${NGRAPH_INSTALL_DIR}/include)
SET(NGRAPH_LIB_DIR         ${NGRAPH_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR})
SET(NGRAPH_SHARED_LIB_NAME libngraph.so)
SET(NGRAPH_CPU_LIB_NAME    libcpu_backend.so)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    SET(NGRAPH_TBB_LIB_NAME    libtbb_debug.so.2)
else()
    SET(NGRAPH_TBB_LIB_NAME    libtbb.so.2)
endif()
#SET(NGRAPH_GIT_REPO        "https://github.com/NervanaSystems/ngraph.git")
SET(NGRAPH_GIT_REPO        "https://github.com/pawelpiotrowicz/ngraph.git")
SET(NGRAPH_SHARED_LIB      ${NGRAPH_LIB_DIR}/${NGRAPH_SHARED_LIB_NAME})
SET(NGRAPH_CPU_LIB         ${NGRAPH_LIB_DIR}/${NGRAPH_CPU_LIB_NAME})
SET(NGRAPH_TBB_LIB         ${NGRAPH_LIB_DIR}/${NGRAPH_TBB_LIB_NAME})
SET(CMAKE_INSTALL_RPATH    "${CMAKE_INSTALL_RPATH}" "${NGRAPH_LIB_DIR}")
# SET(CMAKE_SKIP_BUILD_RPATH FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

ExternalProject_Add(
    ${NGRAPH_PROJECT}
    ${EXTERNAL_PROJECT_LOG_ARGS}
    DEPENDS                  ${MKLDNN_PROJECT} ${MKLML_PROJECT}
    SOURCE_DIR               "/home/pawepiot/workspace/this_one/aipg/scripts/bert/src_ngraph"
 #  GIT_REPOSITORY           ${NGRAPH_GIT_REPO}
 #  GIT_TAG                  ${NGRAPH_GIT_TAG}
 #   PREFIX                   ${NGRAPH_SOURCES_DIR}
  
    TMP_DIR                  "/home/pawepiot/workspace/this_one/aipg/scripts/bert/src_ngraph/tmp-dir" 
    STAMP_DIR                "/home/pawepiot/workspace/this_one/aipg/scripts/bert/src_ngraph/stamp-dir" 
    


    UPDATE_COMMAND           ""
    CMAKE_GENERATOR          ${CMAKE_GENERATOR}
    CMAKE_GENERATOR_PLATFORM ${CMAKE_GENERATOR_PLATFORM}
    CMAKE_GENERATOR_TOOLSET  ${CMAKE_GENERATOR_TOOLSET}
    CMAKE_ARGS               -DNGRAPH_DISTRIBUTED_ENABLE=${NGRAPH_DISTRIBUTED_ENABLE}
    CMAKE_ARGS               -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    CMAKE_ARGS               -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    CMAKE_ARGS               -DCMAKE_INSTALL_PREFIX=${NGRAPH_INSTALL_DIR}
    CMAKE_ARGS               -DNGRAPH_UNIT_TEST_ENABLE=FALSE
    CMAKE_ARGS               -DNGRAPH_TOOLS_ENABLE=FALSE
    CMAKE_ARGS               -DNGRAPH_INTERPRETER_ENABLE=FALSE
    CMAKE_ARGS               -DNGRAPH_DEX_ONLY=TRUE
    CMAKE_ARGS               -DNGRAPH_ENABLE_CPU_CONV_AUTO=FALSE
    CMAKE_ARGS               -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    CMAKE_ARGS               -DMKLDNN_INCLUDE_DIR=${MKLDNN_INC_DIR}
    CMAKE_ARGS               -DMKLDNN_LIB_DIR=${MKLDNN_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}
    CMAKE_ARGS               -DMKLML_LIB_DIR=${MKLML_INSTALL_DIR}/lib
)

IF(${WITH_NGRAPH_NNP})
    IF(${NGRAPH_ARGON_API_PATH} STREQUAL "")
        MESSAGE(FATAL_ERROR "NGRAPH_ARGON_API_PATH is not set")
    ENDIF()

    SET(NGRAPH_NNP_PROJECT         "extern_ngraph_nnp")
    SET(NGRAPH_NNP_GIT_TAG         "72ab741a5781ebcfd0955a9fe09ca58284c5d754")
    SET(NGRAPH_NNP_SOURCES_DIR     ${THIRD_PARTY_PATH}/ngraph/nnp-transformer)
    SET(NGRAPH_NNP_LIB_NAME        libnnp_backend.so)
    SET(NGRAPH_NNP_GIT_REPO        "https://github.com/NervanaSystems/nnp-transformer.git")
    SET(NGRAPH_NNP_LIB             ${NGRAPH_LIB_DIR}/${NGRAPH_NNP_LIB_NAME})

    ExternalProject_Add(
        ${NGRAPH_NNP_PROJECT}
        ${EXTERNAL_PROJECT_LOG_ARGS}
        DEPENDS             ${NGRAPH_PROJECT}
        GIT_REPOSITORY      ${NGRAPH_NNP_GIT_REPO}
        GIT_TAG             ${NGRAPH_NNP_GIT_TAG}
        PREFIX              ${NGRAPH_NNP_SOURCES_DIR}
        UPDATE_COMMAND      ""
        BUILD_ALWAYS        1
        CMAKE_ARGS          -DARGON_API_PATH=${NGRAPH_ARGON_API_PATH}
        CMAKE_ARGS          -DARGON_PREBUILT=TRUE
        CMAKE_ARGS          -DNNPTR_RPATH=/usr/lib/x86_64-linux-gnu/
        CMAKE_ARGS          -DCMAKE_INSTALL_PREFIX=${NGRAPH_INSTALL_DIR}/nnp
        CMAKE_ARGS          -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        CMAKE_ARGS          -DNGRAPH_SRC_DIR=${NGRAPH_SOURCES_DIR}/src/${NGRAPH_PROJECT}
	CMAKE_ARGS          -DPREBUILD_NGRAPH_PATH=${NGRAPH_INSTALL_DIR}/
    )
ENDIF()

# Some Paddle compilation units depend on these, but have no declared
# dependence (direct or indirect) on the 'ngraph' target.  So we'll
# just define them globally to ensure they're in effect everywhere
# relevant.
add_definitions(-DPADDLE_WITH_NGRAPH)
include_directories(${NGRAPH_INC_DIR})

IF(${WITH_NGRAPH_NNP})
    add_dependencies(ngraph ${NGRAPH_NNP_PROJECT} ${NGRAPH_PROJECT})
    #target_compile_definitions(ngraph INTERFACE -DPADDLE_WITH_NGRAPH)
    #target_include_directories(ngraph INTERFACE ${NGRAPH_INC_DIR})
    target_link_libraries(ngraph INTERFACE ${NGRAPH_SHARED_LIB} ${NGRAPH_NNP_LIB})
ELSE()
    add_dependencies(ngraph ${NGRAPH_PROJECT})
    #target_compile_definitions(ngraph INTERFACE -DPADDLE_WITH_NGRAPH)
    #target_include_directories(ngraph INTERFACE ${NGRAPH_INC_DIR})
    target_link_libraries(ngraph INTERFACE ${NGRAPH_SHARED_LIB})
ENDIF()
