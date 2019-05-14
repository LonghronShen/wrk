project (wrk C CXX)
cmake_minimum_required (VERSION 3.12)

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

set (CMAKE_MACOSX_RPATH 1)
set (CXX_STD 17 CACHE STRING "Set to 11 or 14 to enable C++11 or C++17 builds, respectively." FORCE)
set (C_STD 11 CACHE STRING "Set to 99 or 11 to enable C99 or C11 builds, respectively." FORCE)

if (NOT CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE "Debug")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")
else ()
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
endif (NOT CMAKE_BUILD_TYPE)

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

set(OPENSSL_USE_STATIC_LIBS TRUE)

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
    else ()
        add_subdirectory(libs/openssl)
        set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs/openssl/)
    endif()
endif()

INCLUDE(FindLuaJIT)

find_package(LuaJIT)
if (NOT LUA_FOUND)
    add_subdirectory(libs/luajit EXCLUDE_FROM_ALL)
    set(LUA_INCLUDE_DIR 
        ${CMAKE_CURRENT_BINARY_DIR}/
        ${CMAKE_CURRENT_SOURCE_DIR}/libs/luajit/luajit/src/)
    set(LUA_LIBRARIES liblua-static)
endif()

enable_language(LUAJIT OPTIONAL)

include_directories(
    ${OPENSSL_INCLUDE_DIR}
    ${LUA_INCLUDE_DIR}
    "${CMAKE_CURRENT_LIST_DIR}/src/"
)

FILE(GLOB WRK_SCRIPT_FILES
    ${CMAKE_CURRENT_LIST_DIR}/src/*.lua
)

FILE(GLOB WRK_HEADER_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.h
)

FILE(GLOB WRK_SOURCE_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.c
)

FILE(GLOB WRK_LIB_SOURCE_FILES
	${CMAKE_CURRENT_LIST_DIR}/src/*.cpp
)

SET(WRK_CLI_SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/src/wrk.c")

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

add_library(libwrk SHARED ${WRK_LIB_SOURCE_FILES} ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk wrk_scripts OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES} ${EXTRA_LIBRATIES})

add_library(libwrk-static STATIC ${WRK_LIB_SOURCE_FILES} ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(libwrk-static wrk_scripts OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES} ${EXTRA_LIBRATIES})

ADD_EXECUTABLE(wrk ${WRK_CLI_SOURCE_FILES} ${WRK_HEADER_FILES} ${WRK_SOURCE_FILES})
target_link_libraries(wrk wrk_scripts OpenSSL::SSL OpenSSL::Crypto ${LUA_LIBRARIES} ${EXTRA_LIBRATIES})
