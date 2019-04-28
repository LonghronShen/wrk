project (wrk C CXX ASM)
cmake_minimum_required (VERSION 3.12)

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

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
endif(NOT WIN32)

find_package(openssl)
if (NOT OPENSSL_FOUND)
    add_subdirectory(libs/openssl)
    set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/openssl/)
endif()

find_package(lua)
if (NOT LUA_FOUND)
    add_subdirectory(libs/luajit)
    set(LUA_INCLUDE_DIR 
        ${CMAKE_CURRENT_BINARY_DIR}/luaconf.h 
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/lua.h 
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/luajit.h 
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/lua.hpp 
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/lualib.h 
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/lauxlib.h)
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

if (WIN32)
    execute_process(COMMAND CMD /c "git describe --tags --always --dirty" OUTPUT_VARIABLE VER)
elseif (UNIX)
    execute_process(COMMAND git describe --tags --always --dirty OUTPUT_VARIABLE VER)
else()
    message(fatal "Unsupported platform detected.")
endif()

string(REGEX REPLACE "\n$" "" VER "${VER}")
set(VER_STRING "${VER}")
message("Wrk version: ${VER_STRING}")

configure_file(${CMAKE_CURRENT_LIST_DIR}/src/version.c.in version.c)

list(APPEND WRK_SOURCE_FILES "version.c")

add_library(libwrk SHARED ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk OpenSSL::SSL OpenSSL::Crypto lualib)

add_library(libwrk-static STATIC ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk-static OpenSSL::SSL OpenSSL::Crypto lualib)

ADD_EXECUTABLE(wrk "${CMAKE_CURRENT_LIST_DIR}/src/wrk.c" ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(wrk OpenSSL::SSL OpenSSL::Crypto lualib)
