# This file sets the basic flags for the LUAJIT compiler
if(NOT CMAKE_LUAJIT_COMPILE_OBJECT)
    set(CMAKE_LUAJIT_COMPILE_OBJECT "luajit -b <SOURCE> <OBJECT>")
endif()
set(CMAKE_LUAJIT_INFORMATION_LOADED 1)