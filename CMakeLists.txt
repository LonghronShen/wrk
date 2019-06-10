cmake_minimum_required(VERSION 3.14)

IF(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
	SET(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "CMAKE_TOOLCHAIN_FILE")
ENDIF()

project(wrk C CXX)

SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE STRING "CMAKE_LIBRARY_OUTPUT_DIRECTORY" FORCE)
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE STRING "CMAKE_RUNTIME_OUTPUT_DIRECTORY" FORCE)
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE STRING "CMAKE_ARCHIVE_OUTPUT_DIRECTORY" FORCE)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

set(CMAKE_MACOSX_RPATH 1)
set(CXX_STD 17 CACHE STRING "Set to 11 or 14 to enable C++11 or C++17 builds, respectively." FORCE)
set(C_STD 11 CACHE STRING "Set to 99 or 11 to enable C99 or C11 builds, respectively." FORCE)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
endif()

if(NOT WIN32)
    include(CheckCXXCompilerFlag)
    CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
    if(COMPILER_SUPPORTS_CXX14)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -Wall")
    else()
        message(FATAL_ERROR "Compiler ${CMAKE_CXX_COMPILER} has no C++14 support.")
    endif()
    if(APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000")
    endif()
endif()

set(OPENSSL_USE_STATIC_LIBS TRUE)
set(CMAKE_LUAJIT_CREATE_STATIC_LIBRARY 1)

if(APPLE)
    find_package(openssl REQUIRED)
else()
    find_package(OpenSSL)
    if (OPENSSL_FOUND)
        find_package (Threads REQUIRED)
        find_package (LibDL REQUIRED)

        if(THREADS_HAVE_PTHREAD_ARG)
            add_compile_options("-pthread")
        endif()
        if(CMAKE_THREAD_LIBS_INIT)
            list(APPEND EXTRA_LIBRATIES "${CMAKE_THREAD_LIBS_INIT}")
        endif()

        if(LIBDL_FOUND)
            list(APPEND EXTRA_LIBRATIES "${LIBDL_LIBRARY}")
        endif()
    else()
        add_subdirectory(libs/openssl EXCLUDE_FROM_ALL)
        set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/openssl/)
    endif()
endif()

include(FindLuaJIT)

find_package(LuaJIT)
if(NOT LUA_FOUND)
    set(USE_LUAJIT_FROM_SOURCE 1)
    add_subdirectory(libs/luajit EXCLUDE_FROM_ALL)
    set(LUA_INCLUDE_DIR 
        ${CMAKE_CURRENT_BINARY_DIR}/
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/)
    set(LUA_LIBRARIES liblua-static)
else()
    set(USE_LUAJIT_FROM_SOURCE 0)
endif()

enable_language(LUAJIT OPTIONAL)

include_directories(
    ${OPENSSL_INCLUDE_DIR}
    ${LUA_INCLUDE_DIR}
    "${CMAKE_CURRENT_LIST_DIR}/src/"
)

file(GLOB WRK_SCRIPT_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/*.lua
)

file(GLOB WRK_HEADER_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.h
)

file(GLOB WRK_SOURCE_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.c
)

file(GLOB WRK_LIB_SOURCE_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.cpp
)

set(WRK_CLI_SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/src/wrk.c")

list(REMOVE_ITEM WRK_SOURCE_FILES ${WRK_CLI_SOURCE_FILES})
list(FILTER WRK_SOURCE_FILES EXCLUDE REGEX "ae_.+\.c")
list(REMOVE_DUPLICATES WRK_SOURCE_FILES)

if (WIN32)
    execute_process(COMMAND CMD /c "git describe --tags --always --dirty" OUTPUT_VARIABLE VER)
elseif (UNIX)
    execute_process(COMMAND git describe --tags --always --dirty OUTPUT_VARIABLE VER)
    if(APPLE)
        execute_process(COMMAND sw_vers -productVersion OUTPUT_VARIABLE MACOSX_DEPLOYMENT_TARGET)
        string(REGEX REPLACE "\n$" "" MACOSX_DEPLOYMENT_TARGET "${MACOSX_DEPLOYMENT_TARGET}")
        message(STATUS "MACOSX_DEPLOYMENT_TARGET: ${MACOSX_DEPLOYMENT_TARGET}")
    endif()
else()
    message(fatal "Unsupported platform detected.")
endif()

string(REGEX REPLACE "\n$" "" VER "${VER}")
message(STATUS "Wrk version: ${VER}")

configure_file(${CMAKE_CURRENT_LIST_DIR}/src/version.c.in version.c)

list(APPEND WRK_SOURCE_FILES "version.c")

add_library(wrk_scripts STATIC ${WRK_SCRIPT_FILES})

if(USE_LUAJIT_FROM_SOURCE)
    add_dependencies(wrk_scripts luajit)
endif()

add_library(libwrk SHARED ${WRK_LIB_SOURCE_FILES} ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk wrk_scripts OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES} ${EXTRA_LIBRATIES})

add_library(libwrk-static STATIC ${WRK_LIB_SOURCE_FILES} ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk-static wrk_scripts OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES} ${EXTRA_LIBRATIES})

ADD_EXECUTABLE(wrk ${WRK_CLI_SOURCE_FILES} ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(wrk wrk_scripts OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES} ${EXTRA_LIBRATIES})
