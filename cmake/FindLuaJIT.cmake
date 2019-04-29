# Copyright (c) 2013 Martin Felis &lt;martin@fysx.org&gt;
# License: Public Domain (Unlicense: http://unlicense.org/)
#
# Try to find Lua or LuaJIT depending on the variable LUA_USE_LUAJIT.
# Sets the following variables:
#   Lua_FOUND
#   LUA_INCLUDE_DIR
#   LUA_LIBRARY
#
# Use it in a CMakeLists.txt script as:
#
#   OPTION (LUA_USE_LUAJIT "Use LuaJIT instead of default Lua" OFF)
#   UNSET(Lua_FOUND CACHE)
#   UNSET(LUA_INCLUDE_DIR CACHE)
#   UNSET(LUA_LIBRARY CACHE)
#   FIND_PACKAGE (Lua REQUIRED)

OPTION (LUA_USE_LUAJIT "Use LuaJIT instead of default Lua" ON)

IF (LUA_USE_LUAJIT)
    SET (Lua_FOUND FALSE)
    SET (LUA_INTERPRETER_TYPE "")

    SET (LUA_INTERPRETER_TYPE "LuaJIT")

    # Always search for non-versioned lua first (recommended)
    SET(_POSSIBLE_LUA_INCLUDE include include/lua)
    SET(_POSSIBLE_LUA_EXECUTABLE lua)
    SET(_POSSIBLE_LUA_LIBRARY lua)

    # Determine possible naming suffixes (there is no standard for this)
    IF(Lua_FIND_VERSION_MAJOR AND Lua_FIND_VERSION_MINOR)
        SET(_POSSIBLE_SUFFIXES "${Lua_FIND_VERSION_MAJOR}${Lua_FIND_VERSION_MINOR}" "${Lua_FIND_VERSION_MAJOR}.${Lua_FIND_VERSION_MINOR}" "-${Lua_FIND_VERSION_MAJOR}.${Lua_FIND_VERSION_MINOR}")
    ELSE(Lua_FIND_VERSION_MAJOR AND Lua_FIND_VERSION_MINOR)
        SET(_POSSIBLE_SUFFIXES "21" "2.1" "-2.1" "20" "2.0" "-2.0")
    ENDIF(Lua_FIND_VERSION_MAJOR AND Lua_FIND_VERSION_MINOR)

    # Set up possible search names and locations
    FOREACH(_SUFFIX ${_POSSIBLE_SUFFIXES})
        LIST(APPEND _POSSIBLE_LUA_INCLUDE "include/luajit${_SUFFIX}")
        LIST(APPEND _POSSIBLE_LUA_EXECUTABLE "luajit${_SUFFIX}")
        LIST(APPEND _POSSIBLE_LUA_LIBRARY "luajit${_SUFFIX}")
    ENDFOREACH(_SUFFIX)

    # Find the lua executable
    FIND_PROGRAM(LUA_EXECUTABLE
        NAMES ${_POSSIBLE_LUA_EXECUTABLE}
    )

    # Find the lua header
    FIND_PATH(LUA_INCLUDE_DIR lua.h
        HINTS
        $ENV{LUA_DIR}
        PATH_SUFFIXES ${_POSSIBLE_LUA_INCLUDE}
        PATHS
        ~/Library/Frameworks
        /Library/Frameworks
        /usr/local
        /usr
        /sw # Fink
        /opt/local # DarwinPorts
        /opt/csw # Blastwave
        /opt
    )

    # Find the lua library
    FIND_LIBRARY(LUA_LIBRARY 
        NAMES ${_POSSIBLE_LUA_LIBRARY}
        HINTS
        $ENV{LUA_DIR}
        PATH_SUFFIXES lib64 lib
        PATHS
        ~/Library/Frameworks
        /Library/Frameworks
        /usr/local
        /usr
        /sw
        /opt/local
        /opt/csw
        /opt
    )

    IF(LUA_LIBRARY)
        # include the math library for Unix
        IF(UNIX AND NOT APPLE)
            FIND_LIBRARY(LUA_MATH_LIBRARY m)
            SET( LUA_LIBRARIES "${LUA_LIBRARY};${LUA_MATH_LIBRARY}" CACHE STRING "Lua Libraries")
        # For Windows and Mac, don't need to explicitly include the math library
        ELSE(UNIX AND NOT APPLE)
            SET( LUA_LIBRARIES "${LUA_LIBRARY}" CACHE STRING "Lua Libraries")
        ENDIF(UNIX AND NOT APPLE)
    ENDIF(LUA_LIBRARY)

    # Determine Lua version
    IF(LUA_INCLUDE_DIR AND EXISTS "${LUA_INCLUDE_DIR}/lua.h")
        FILE(STRINGS "${LUA_INCLUDE_DIR}/lua.h" lua_version_str REGEX "^#define[ \t]+LUA_RELEASE[ \t]+\"Lua .+\"")
        STRING(REGEX REPLACE "^#define[ \t]+LUA_RELEASE[ \t]+\"Lua ([^\"]+)\".*" "\\1" LUA_VERSION_STRING "${lua_version_str}")
        UNSET(lua_version_str)
    ENDIF()

    INCLUDE(FindPackageHandleStandardArgs)
    # handle the QUIETLY and REQUIRED arguments and set LUA_FOUND to TRUE if 
    # all listed variables are TRUE
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(
        Lua
        REQUIRED_VARS LUA_LIBRARIES LUA_INCLUDE_DIR
        VERSION_VAR LUA_VERSION_STRING)

    MARK_AS_ADVANCED(LUA_INCLUDE_DIR LUA_LIBRARIES LUA_LIBRARY LUA_MATH_LIBRARY LUA_EXECUTABLE)
ELSE (LUA_USE_LUAJIT)
    FIND_PACKAGE (Lua)
ENDIF(LUA_USE_LUAJIT)
