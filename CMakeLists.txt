project (wrk C CXX)
cmake_minimum_required (VERSION 3.12)

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

set (CMAKE_MACOSX_RPATH 1)
set (CXX_STD 17 CACHE STRING "Set to 11 or 14 to enable C++11 or C++17 builds, respectively." FORCE)
set (C_STD 11 CACHE STRING "Set to 99 or 11 to enable C99 or C11 builds, respectively." FORCE)

if (NOT CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE "Debug")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
else()
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
endif(NOT CMAKE_BUILD_TYPE)

if (NOT WIN32)
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
endif(NOT WIN32)

if(APPLE)
    find_package(openssl REQUIRED)
else()
    find_package(openssl)
    if (NOT OPENSSL_FOUND)
        add_subdirectory(libs/openssl EXCLUDE_FROM_ALL)
        set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/openssl/)
    endif()
endif()

find_package(lua)
if (NOT LUA_FOUND)
    add_subdirectory(libs/luajit EXCLUDE_FROM_ALL)
    set(LUA_INCLUDE_DIR 
        ${CMAKE_CURRENT_BINARY_DIR}/
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/)
    set(LUA_LIBRARIES liblua-static)
endif()

macro(add_luajit_target _target)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_target}
    COMMAND luajit ARGS ${CMAKE_CURRENT_BINARY_DIR}/${_target} ${ARGN}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS luajit ${ARGN}
  )
endmacro(add_luajit_target)

include_directories(
    ${OPENSSL_INCLUDE_DIR}
    ${LUA_INCLUDE_DIR}
    "${CMAKE_CURRENT_LIST_DIR}/src/"
)

FILE(GLOB WRK_HEADER_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.h
)

FILE(GLOB WRK_SOURCE_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.c
)

list(REMOVE_ITEM WRK_SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/src/wrk.c")
list(FILTER WRK_SOURCE_FILES EXCLUDE REGEX "ae_.+\.c")

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

add_library(libwrk SHARED ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES})

add_library(libwrk-static STATIC ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk-static OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES})

ADD_EXECUTABLE(wrk "${CMAKE_CURRENT_LIST_DIR}/src/wrk.c" ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(wrk OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES})
