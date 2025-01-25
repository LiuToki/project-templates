# プログラムの設定いろいろ
message("${CMAKE_PROJECT_NAME} aa ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
# Configure files
if (MSVC)
	configure_file(
		${CMAKE_CURRENT_SOURCE_DIR}/resource.rc.in
		${CMAKE_CURRENT_BINARY_DIR}/resource.rc
		@ONLY)
endif()

configure_file(
	${CMAKE_CURRENT_SOURCE_DIR}/version.h.in
	${CMAKE_CURRENT_BINARY_DIR}/version.h
	@ONLY)

# Header files
set(H_FILES
#	version.h
)

# Source files
set(CXX_FILES
	main.cpp
)

# フィルタリング(ルートでUSE_FOLDERSのプロパティ設定してあること！)
source_group("Header Files" FILES ${H_FILES})
source_group("Source Files" FILES ${CXX_FILES})

# Build executable
add_executable(${PROJECT_NAME}
	${H_FILES}
	${CXX_FILES}
)

if(MSVC)
  target_sources(${PROJECT_NAME}
    PRIVATE
      ${CMAKE_CURRENT_BINARY_DIR}/resource.rc
  )
endif()

# Include
set(INCS
    # ${OpenCV_INCLUDE_DIRS}
)

# version.hはバイナリが生成されるディレクトリでひっぱる
target_include_directories(${PROJECT_NAME}
PRIVATE
  "${CMAKE_CURRENT_BINARY_DIR}"
# PUBLIC <foo> や INTERFACE <bar> といった指定も必要に応じて
)
# include_directories(${PROJECT_NAME})

# Link libraries
set(LIBS
#	${Boost_LIBRARIES}
)

# include_directories(${Boost_INCLUDE_DIRS})

# static link
target_link_libraries(${PROJECT_NAME} PRIVATE ${LIBS})
set_target_properties(${PROJECT_NAME} PROPERTIES VS_USER_PROPS ${VCPKG_ROOT}/scripts/buildsystems/msbuild/vcpkg.targets)

# Options
# C++の標準規格の指定.
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_23)

if(${CMAKE_CXX_COMPILER_ID} STREQUAL GNU)
  target_compile_options(${PROJECT_NAME} PUBLIC -Wno-unused-parameter)
elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC)
  target_compile_definitions(${PROJECT_NAME} PRIVATE -W4)

  target_compile_options(${PROJECT_NAME} PRIVATE "-permissive-")
  target_compile_options(${PROJECT_NAME} PRIVATE "-EHsc")
  target_compile_options(${PROJECT_NAME} PRIVATE "-bigobj")

  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:-D_DEBUG>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:-MDd>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:-Ob0>
  )# Disables inline expansion
  target_compile_options(
    ${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:-Od>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:-RTC1>
  )# Enables run-time error checking.
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:-Zi>
  )# Generates complete debugging information.

  target_compile_options(${PROJECT_NAME}
                         PRIVATE $<$<CONFIG:RelWithDebInfo>:-D_NDEBUG>)
  target_compile_options(${PROJECT_NAME}
                         PRIVATE $<$<CONFIG:RelWithDebInfo>:-DNDEBUG>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:RelWithDebInfo>:-MT>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:RelWithDebInfo>:-O2>
  )# Creates fast code.
  target_compile_options(
    ${PROJECT_NAME} PRIVATE $<$<CONFIG:RelWithDebInfo>:-Ob2>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:RelWithDebInfo>:-Oi>
  )# Generates intrinsic functions.
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:RelWithDebInfo>:-Ot>
  )# Favors fast code.
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:RelWithDebInfo>:-Zi>
  )# Generates complete debugging information.

  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-D_NDEBUG>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-DNDEBUG>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-MT>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-O2>
  )# Creates fast code.
  target_compile_options(
    ${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-Ob2>)
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-Oi>
  )# Generates intrinsic functions.
  target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:-Ot>
  )# Favors fast code.
else()
  target_compile_options(${PROJECT_NAME} PRIVATE -O3)
  target_compile_options(${PROJECT_NAME} PRIVATE -Wall)
  target_compile_options(${PROJECT_NAME} PRIVATE -Wextra -Wpointer-arith)
  target_compile_options(${PROJECT_NAME} PRIVATE -Werror)
endif()

# テストオプションが有効な場合、テストを追加
if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()