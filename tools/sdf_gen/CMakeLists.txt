cmake_minimum_required(VERSION 3.7)

project(sdf_gen)

set(SDF_GEN_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(SDF_GEN_SRC
	${SDF_GEN_SRC_DIR}/main.c
	${SDF_GEN_SRC_DIR}/sdf.c
)
include_directories(${SDF_GEN_SRC_DIR})

add_executable(sdf_gen ${SDF_GEN_SRC})

install(TARGETS sdf_gen DESTINATION tools)

