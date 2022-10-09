cmake_minimum_required(VERSION 3.13.0 FATAL_ERROR)

# pico-sdk path. Not to set to envirment paths.
set(PICO_SDK_PATH ${CMAKE_CURRENT_SOURCE_DIR}/libs/pico-sdk)

# initialize the SDK directly
include (${PICO_SDK_PATH}/pico_sdk_init.cmake)

# Compile settings
enable_language(CXX)
set(CMAKE_CXX_STANDARD 17) # C++17...check your compiler version
set(CMAKE_CXX_STANDARD_REQUIRED ON) #...is required...
set(CMAKE_CXX_EXTENSIONS OFF) #...without compiler extensions like gnu++11

# Build type
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# Update compiler settings.
if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
	# Update if necessary
#	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wno-long-long -pedantic")
else()
    message(FATAL_ERROR "Not suported compiler!")
endif()

# Set project settings
set(PROJECT_NAME rp2040-cpp-dev)    # TODO:Project Name
project(${PROJECT_NAME})

# initialize the Raspberry Pi Pico SDK
pico_sdk_init()

## project function set PROJECT_SOURCE_DIR to CMakefile.txt directory, so update path
set(PROJECT_SOURCE_DIR "${PROJECT_SOURCE_DIR}/src")

set(RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build)

# Input files
file(GLOB_RECURSE CXX_FILES ${PROJECT_SOURCE_DIR}/*.cpp)
file(GLOB_RECURSE H_FILES ${PROJECT_SOURCE_DIR}/*.h)

source_group("Header Files" FILES ${H_FILES})
source_group("Source Files" FILES ${CXX_FILES})

# Compile
add_executable(${PROJECT_NAME}
	${H_FILES}
	${CXX_FILES}
)

# Link libraries
set(LIBS
	pico_stdlib
)

# static link
target_link_libraries(${PROJECT_NAME} PRIVATE ${LIBS})

# create map/bin/hex file etc.
pico_add_extra_outputs(${PROJECT_NAME})

# add url via pico_set_program_url
#example_auto_set_url(${PROJECT_NAME})
