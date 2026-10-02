cmake_minimum_required(VERSION 3.19)

if(NOT DEFINED VERSION)
    set(_VERSION_ENV "${CMAKE_SOURCE_DIR}/../.github/version.env")
    if(EXISTS "${_VERSION_ENV}")
        file(STRINGS "${_VERSION_ENV}" _VER_LINE REGEX "^VERSION=")
        if(_VER_LINE)
            string(REGEX REPLACE "^VERSION=" "" VERSION "${_VER_LINE}")
        endif()
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_VERSION_ENV}")
    endif()

    if(NOT VERSION OR "${VERSION}" STREQUAL "" OR "${VERSION}" STREQUAL "rolling")
        execute_process(COMMAND git describe --tags --match "v*" --abbrev=0
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
    endif()

    string(STRIP "${VERSION}" VERSION)
endif()

if(NOT DEFINED GIT_REVISION)
    set(_REVISION_FILE "${CMAKE_SOURCE_DIR}/../REVISION")
    if(EXISTS "${_REVISION_FILE}")
        file(STRINGS "${_REVISION_FILE}" GIT_REVISION LIMIT_COUNT 1)
        string(STRIP "${GIT_REVISION}" GIT_REVISION)
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_REVISION_FILE}")
    else()
        execute_process(COMMAND git rev-parse HEAD
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE GIT_REVISION
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
    endif()

    if("${GIT_REVISION}" STREQUAL "")
        set(GIT_REVISION "unknown")
    endif()
endif()

set(DISPLAY_VERSION "${VERSION}")

execute_process(COMMAND git rev-parse --abbrev-ref HEAD
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    OUTPUT_VARIABLE _GIT_BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
)
if("${_GIT_BRANCH}" STREQUAL "dev")
    execute_process(COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE _SHORT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    )
    if(NOT "${_SHORT_HASH}" STREQUAL "")
        set(DISPLAY_VERSION "${VERSION}-dev+${_SHORT_HASH}")
    endif()
endif()

string(REGEX REPLACE "^v" "" VERSION "${VERSION}")
string(REGEX REPLACE "^v" "" DISPLAY_VERSION "${DISPLAY_VERSION}")

if(VERSION)
    project(caelestia-shell VERSION ${VERSION} LANGUAGES C CXX)
else()
    project(caelestia-shell LANGUAGES C CXX)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
    message(STATUS "ccache found — compiler caching enabled")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(DISTRIBUTOR "Unset" CACHE STRING "Distributor")
set(ENABLE_MODULES "extras;plugin;shell;m3shapes" CACHE STRING "Modules to build/install")
set(INSTALL_LIBDIR "usr/lib/caelestia" CACHE STRING "Library install dir")
set(INSTALL_QMLDIR "usr/lib/qt6/qml" CACHE STRING "QML install dir")
set(INSTALL_QSCONFDIR "etc/xdg/quickshell/caelestia" CACHE STRING "Quickshell config install dir")

if("m3shapes" IN_LIST ENABLE_MODULES)
    message(STATUS "Fetching M3Shapes module")
    include(FetchContent)
    set(M3SHAPES_REV bdc327b29f95394a732baf3c9b19658ba23755b6)

    option(CAELESTIA_CACHE_DEPS "Keep FetchContent sources outside the build tree" OFF)

    if(CAELESTIA_CACHE_DEPS)
        if(DEFINED ENV{XDG_CACHE_HOME} AND NOT "$ENV{XDG_CACHE_HOME}" STREQUAL "")
            set(_CAELESTIA_CACHE "$ENV{XDG_CACHE_HOME}/caelestia-kde")
        else()
            set(_CAELESTIA_CACHE "$ENV{HOME}/.cache/caelestia-kde")
        endif()
        set(_M3SHAPES_SOURCE_DIR "${_CAELESTIA_CACHE}/m3shapes-${M3SHAPES_REV}")
    else()
        set(_M3SHAPES_SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/m3shapes-${M3SHAPES_REV}")
    endif()

    FetchContent_Declare(
        m3shapes_external
        GIT_REPOSITORY https://github.com/soramanew/m3shapes.git
        GIT_TAG        ${M3SHAPES_REV}
        SOURCE_DIR     "${_M3SHAPES_SOURCE_DIR}"
    )
    FetchContent_MakeAvailable(m3shapes_external)
    message(STATUS "Done fetching M3Shapes module")

    if(TARGET m3shapesplugin)
        set_target_properties(m3shapesplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
    endif()
endif()

add_compile_definitions(
    QT_NO_CAST_FROM_ASCII
    QT_NO_CAST_TO_ASCII
    QT_NO_CAST_FROM_BYTEARRAY
)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wfloat-equal -Woverloaded-virtual
    -Wsign-conversion -Wredundant-decls -Wswitch
    -Wunreachable-code
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wunused-lambda-capture)
endif()

if("extras" IN_LIST ENABLE_MODULES)
    add_subdirectory(extras)
endif()

if("plugin" IN_LIST ENABLE_MODULES)
    add_subdirectory(plugin)
endif()

if("shell" IN_LIST ENABLE_MODULES)
    foreach(dir assets defaults modules panelFamilies services translations)
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${dir})
            install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${dir}
                    DESTINATION ${INSTALL_QSCONFDIR})
        endif()
    endforeach()

    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts)
        install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/scripts/
                DESTINATION ${INSTALL_QSCONFDIR}/scripts
                PATTERN "qml-lint-conventions.py" EXCLUDE
                PATTERN "menu_perf_stats.py" EXCLUDE)
    endif()

    foreach(qml_file shell.qml GlobalStates.qml ReloadPopup.qml killDialog.qml settings.qml welcome.qml)
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${qml_file})
            install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/${qml_file} DESTINATION "${INSTALL_QSCONFDIR}")
        endif()
    endforeach()

    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE)
        install(FILES LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
    endif()
endif()
