cmake_minimum_required(VERSION 3.24.0 FATAL_ERROR)

# プロパティ設定
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Vcpkg path. Not to set to envirment paths.
set(VCPKG_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/libs/vcpkg)
message(STATUS "VCPKG_ROOT: ${VCPKG_ROOT}")

# Set project settings
# プロジェクト名と実行ファイル名は分けることが多いらしい.
set(PROJECT_NAME cpp-vcpkg)    # TODO:Project Name
project(${PROJECT_NAME} VERSION 0.1.0)	# Set Project Version.

# 言語の指定.
enable_language(CXX)
if (USE_CUDA)
	enable_language(CUDA)
endif()

# Build type
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "vcpkg target: ${VCPKG_TARGET_TRIPLET}")
message(STATUS "vcpkg host: ${VCPKG_HOST_TRIPLET}")

# 出力先はbuild ディレクトリ.
# set(RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

# Use vcpkg toolchain file
message(STATUS "CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")

# 基本戦略としてここでライブラリなど外部のものをセッティングする

# ---------------------------------------------------------------------------
# Boost
# ---------------------------------------------------------------------------

# If needed.
#set(Boost_USE_STATIC_LIBS        ON) # only find static libs
#set(Boost_USE_MULTITHREADED      ON)
#set(Boost_USE_STATIC_RUNTIME    OFF)

# Find libraries
# boost は最後に探しにいかないとCOMPONENTS に指定したやつが無視される(他のBoost を参照しているライブラリでFindBoost 呼ばれてBoost_LIBRARIES の設定上書きされてしまうような感じ？).
#find_package(Boost COMPONENTS log log_setup REQUIRED)	# https://cmake.org/cmake/help/git-master/module/FindBoost.html

# ---------------------------------------------------------------------------
# cpp-vcpkg
# ---------------------------------------------------------------------------

add_subdirectory(cpp-vcpkg)
