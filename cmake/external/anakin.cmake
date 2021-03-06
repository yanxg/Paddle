if (NOT WITH_ANAKIN)
  return()
endif()

option(ANAKIN_ENABLE_OP_TIMER      "Get more detailed information with Anakin op time"        OFF)
if(ANAKIN_ENABLE_OP_TIMER)
  add_definitions(-DPADDLE_ANAKIN_ENABLE_OP_TIMER)
endif()

INCLUDE(ExternalProject)
set(ANAKIN_SOURCE_DIR  ${THIRD_PARTY_PATH}/anakin)
# the anakin install dir is only default one now
set(ANAKIN_INSTALL_DIR ${THIRD_PARTY_PATH}/anakin/src/extern_anakin/output)
set(ANAKIN_INCLUDE     ${ANAKIN_INSTALL_DIR})
set(ANAKIN_LIBRARY     ${ANAKIN_INSTALL_DIR})
set(ANAKIN_SHARED_LIB  ${ANAKIN_LIBRARY}/libanakin.so)
set(ANAKIN_SABER_LIB   ${ANAKIN_LIBRARY}/libanakin_saber_common.so)

# TODO(luotao): ANAKIN_MODLE_URL etc will move to demo ci later.
set(INFERENCE_URL "http://paddle-inference-dist.bj.bcebos.com")
set(ANAKIN_MODLE_URL "${INFERENCE_URL}/mobilenet_v2.anakin.bin")
set(ANAKIN_RNN_MODLE_URL "${INFERENCE_URL}/anakin_test%2Fditu_rnn.anakin2.model.bin")
set(ANAKIN_RNN_DATA_URL "${INFERENCE_URL}/anakin_test%2Fditu_rnn_data.txt")
execute_process(COMMAND bash -c "mkdir -p ${ANAKIN_SOURCE_DIR}")
execute_process(COMMAND bash -c "cd ${ANAKIN_SOURCE_DIR}; wget -q --no-check-certificate ${ANAKIN_MODLE_URL} -N")
execute_process(COMMAND bash -c "cd ${ANAKIN_SOURCE_DIR}; wget -q --no-check-certificate ${ANAKIN_RNN_MODLE_URL} -N")
execute_process(COMMAND bash -c "cd ${ANAKIN_SOURCE_DIR}; wget -q --no-check-certificate ${ANAKIN_RNN_DATA_URL} -N")

include_directories(${ANAKIN_INCLUDE})
include_directories(${ANAKIN_INCLUDE}/saber/)
include_directories(${ANAKIN_INCLUDE}/saber/core/)
include_directories(${ANAKIN_INCLUDE}/saber/funcs/impl/x86/)
include_directories(${ANAKIN_INCLUDE}/saber/funcs/impl/cuda/base/cuda_c/)

set(ANAKIN_COMPILE_EXTRA_FLAGS
    -Wno-error=unused-but-set-variable -Wno-unused-but-set-variable
    -Wno-error=unused-variable -Wno-unused-variable
    -Wno-error=format-extra-args -Wno-format-extra-args
    -Wno-error=comment -Wno-comment 
    -Wno-error=format -Wno-format 
    -Wno-error=maybe-uninitialized -Wno-maybe-uninitialized
    -Wno-error=switch -Wno-switch
    -Wno-error=return-type -Wno-return-type
    -Wno-error=non-virtual-dtor -Wno-non-virtual-dtor
    -Wno-error=ignored-qualifiers
    -Wno-ignored-qualifiers
    -Wno-sign-compare
    -Wno-reorder
    -Wno-error=cpp)

ExternalProject_Add(
    extern_anakin
    ${EXTERNAL_PROJECT_LOG_ARGS}
    DEPENDS             ${MKLML_PROJECT}
    GIT_REPOSITORY      "https://github.com/PaddlePaddle/Anakin"
    GIT_TAG             "9424277cf9ae180a14aff09560d3cd60a49c76d2"
    PREFIX              ${ANAKIN_SOURCE_DIR}
    UPDATE_COMMAND      ""
    CMAKE_ARGS          -DUSE_GPU_PLACE=YES
                        -DUSE_X86_PLACE=YES
                        -DBUILD_WITH_UNIT_TEST=NO
                        -DPROTOBUF_ROOT=${THIRD_PARTY_PATH}/install/protobuf
                        -DMKLML_ROOT=${THIRD_PARTY_PATH}/install/mklml
                        -DCUDNN_ROOT=${CUDNN_ROOT}
                        -DCUDNN_INCLUDE_DIR=${CUDNN_INCLUDE_DIR}
                        -DENABLE_OP_TIMER=${ANAKIN_ENABLE_OP_TIMER}
                        ${EXTERNAL_OPTIONAL_ARGS}
    CMAKE_CACHE_ARGS    -DCMAKE_INSTALL_PREFIX:PATH=${ANAKIN_INSTALL_DIR}
)

message(STATUS "Anakin for inference is enabled")
message(STATUS "Anakin is set INCLUDE:${ANAKIN_INCLUDE} LIBRARY:${ANAKIN_LIBRARY}")

add_library(anakin_shared SHARED IMPORTED GLOBAL)
set_property(TARGET anakin_shared PROPERTY IMPORTED_LOCATION ${ANAKIN_SHARED_LIB})
add_dependencies(anakin_shared extern_anakin protobuf mklml)

add_library(anakin_saber SHARED IMPORTED GLOBAL)
set_property(TARGET anakin_saber PROPERTY IMPORTED_LOCATION ${ANAKIN_SABER_LIB})
add_dependencies(anakin_saber extern_anakin protobuf mklml)

list(APPEND external_project_dependencies anakin_shared anakin_saber)
