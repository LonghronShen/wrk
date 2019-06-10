# Find the compiler
if (LUA_FOUND)
    set (CMAKE_LUAJIT_COMPILER LUA_EXECUTABLE)
else (LUA_FOUND)
    message(STATUS "Failed to find the globally installed luajit compiler.")
    if (WIN32)
        set (CMAKE_LUAJIT_COMPILER ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/luajit.exe)
    else (WIN32)
        set (CMAKE_LUAJIT_COMPILER ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/luajit)
    endif (WIN32)
    message(STATUS "Using local compiled instead: " ${CMAKE_LUAJIT_COMPILER})
endif (LUA_FOUND)

mark_as_advanced(CMAKE_LUAJIT_COMPILER)

set(CMAKE_LUAJIT_SOURCE_FILE_EXTENSIONS lua;luajit)
set(CMAKE_LUAJIT_OUTPUT_EXTENSION .o)
set(CMAKE_LUAJIT_COMPILER_ENV_VAR "LUAJIT")

# Configure variables set in this file for fast reload later on
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLUAJITCompiler.cmake.in
               ${CMAKE_PLATFORM_INFO_DIR}/CMakeLUAJITCompiler.cmake)