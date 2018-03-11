# Minimum CMake required
cmake_minimum_required(VERSION 2.8.12)

if(protobuf_VERBOSE)
    message(STATUS "Protocol Buffers Configuring...")
endif()

# CMake policies
cmake_policy(SET CMP0022 NEW)

if(POLICY CMP0048)
    cmake_policy(SET CMP0048 NEW)
endif()

# Options
option(protobuf_BUILD_TESTS "Build tests" ON)
option(protobuf_BUILD_EXAMPLES "Build examples" OFF)
option(protobuf_BUILD_PROTOC_BINARIES "Build libprotoc and protoc compiler" ON)
if (BUILD_SHARED_LIBS)
    set(protobuf_BUILD_SHARED_LIBS_DEFAULT ON)
else (BUILD_SHARED_LIBS)
    set(protobuf_BUILD_SHARED_LIBS_DEFAULT OFF)
endif (BUILD_SHARED_LIBS)
option(protobuf_BUILD_SHARED_LIBS "Build Shared Libraries" ${protobuf_BUILD_SHARED_LIBS_DEFAULT})
include(CMakeDependentOption)
cmake_dependent_option(protobuf_MSVC_STATIC_RUNTIME "Link static runtime libraries" ON
        "NOT protobuf_BUILD_SHARED_LIBS" OFF)
set(protobuf_WITH_ZLIB_DEFAULT ON)
option(protobuf_WITH_ZLIB "Build with zlib support" ${protobuf_WITH_ZLIB_DEFAULT})
set(protobuf_DEBUG_POSTFIX "d"
        CACHE STRING "Default debug postfix")
mark_as_advanced(protobuf_DEBUG_POSTFIX)
# User options
include(${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake/protobuf-options.cmake)

# Path to main configure script
set(protobuf_CONFIGURE_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/protobuf/configure.ac")

# Parse configure script
set(protobuf_AC_INIT_REGEX
        "^AC_INIT\\(\\[([^]]+)\\],\\[([^]]+)\\],\\[([^]]+)\\],\\[([^]]+)\\]\\)$")
file(STRINGS "${protobuf_CONFIGURE_SCRIPT}" protobuf_AC_INIT_LINE
        LIMIT_COUNT 1 REGEX "^AC_INIT")
# Description
string(REGEX REPLACE        "${protobuf_AC_INIT_REGEX}" "\\1"
        protobuf_DESCRIPTION    "${protobuf_AC_INIT_LINE}")
# Version
string(REGEX REPLACE        "${protobuf_AC_INIT_REGEX}" "\\2"
        protobuf_VERSION_STRING "${protobuf_AC_INIT_LINE}")
# Contact
string(REGEX REPLACE        "${protobuf_AC_INIT_REGEX}" "\\3"
        protobuf_CONTACT        "${protobuf_AC_INIT_LINE}")
# Parse version tweaks
set(protobuf_VERSION_REGEX "^([0-9]+)\\.([0-9]+)\\.([0-9]+)-?(.*)$")
string(REGEX REPLACE     "${protobuf_VERSION_REGEX}" "\\1"
        protobuf_VERSION_MAJOR "${protobuf_VERSION_STRING}")
string(REGEX REPLACE     "${protobuf_VERSION_REGEX}" "\\2"
        protobuf_VERSION_MINOR "${protobuf_VERSION_STRING}")
string(REGEX REPLACE     "${protobuf_VERSION_REGEX}" "\\3"
        protobuf_VERSION_PATCH "${protobuf_VERSION_STRING}")
string(REGEX REPLACE     "${protobuf_VERSION_REGEX}" "\\4"
        protobuf_VERSION_PRERELEASE "${protobuf_VERSION_STRING}")

set(protobuf_source_dir
        ${CMAKE_CURRENT_SOURCE_DIR}/protobuf
        )
set(protobuf_SOURCE_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}/protobuf
        )
set(LIB_PREFIX
        ${CMAKE_CURRENT_SOURCE_DIR})
set(protobuf_CONFIGURE_SCRIPT
        ${CMAKE_CURRENT_SOURCE_DIR}/protobuf/configure.ac)

# Package version
set(protobuf_VERSION
        "${protobuf_VERSION_MAJOR}.${protobuf_VERSION_MINOR}.${protobuf_VERSION_PATCH}")

if(protobuf_VERSION_PRERELEASE)
    set(protobuf_VERSION "${protobuf_VERSION}-${protobuf_VERSION_PRERELEASE}")
endif()

if(protobuf_VERBOSE)
    message(STATUS "Configuration script parsing status [")
    message(STATUS "  Description : ${protobuf_DESCRIPTION}")
    message(STATUS "  Version     : ${protobuf_VERSION} (${protobuf_VERSION_STRING})")
    message(STATUS "  Contact     : ${protobuf_CONTACT}")
    message(STATUS "]")
endif()

add_definitions(-DGOOGLE_PROTOBUF_CMAKE_BUILD)

find_package(Threads REQUIRED)
if (CMAKE_USE_PTHREADS_INIT)
    add_definitions(-DHAVE_PTHREAD)
endif (CMAKE_USE_PTHREADS_INIT)

set(_protobuf_FIND_ZLIB)
if (protobuf_WITH_ZLIB)
    find_package(ZLIB)
    if (ZLIB_FOUND)
        set(HAVE_ZLIB 1)
        # FindZLIB module define ZLIB_INCLUDE_DIRS variable
        # Set ZLIB_INCLUDE_DIRECTORIES for compatible
        set(ZLIB_INCLUDE_DIRECTORIES ${ZLIB_INCLUDE_DIRECTORIES} ${ZLIB_INCLUDE_DIRS})
        # Using imported target if exists
        if (TARGET ZLIB::ZLIB)
            set(ZLIB_LIBRARIES ZLIB::ZLIB)
            set(_protobuf_FIND_ZLIB "if(NOT ZLIB_FOUND)\n  find_package(ZLIB)\nendif()")
        endif (TARGET ZLIB::ZLIB)
    else (ZLIB_FOUND)
        set(HAVE_ZLIB 0)
        # Explicitly set these to empty (override NOT_FOUND) so cmake doesn't
        # complain when we use them later.
        set(ZLIB_INCLUDE_DIRECTORIES)
        set(ZLIB_LIBRARIES)
    endif (ZLIB_FOUND)
endif (protobuf_WITH_ZLIB)

if (HAVE_ZLIB)
    add_definitions(-DHAVE_ZLIB)
endif (HAVE_ZLIB)

if (protobuf_BUILD_SHARED_LIBS)
    set(protobuf_SHARED_OR_STATIC "SHARED")
else (protobuf_BUILD_SHARED_LIBS)
    set(protobuf_SHARED_OR_STATIC "STATIC")
    # In case we are building static libraries, link also the runtime library statically
    # so that MSVCR*.DLL is not required at runtime.
    # https://msdn.microsoft.com/en-us/library/2kzt1wy3.aspx
    # This is achieved by replacing msvc option /MD with /MT and /MDd with /MTd
    # http://www.cmake.org/Wiki/CMake_FAQ#How_can_I_build_my_MSVC_application_with_a_static_runtime.3F
    if (MSVC AND protobuf_MSVC_STATIC_RUNTIME)
        foreach(flag_var
                CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            if(${flag_var} MATCHES "/MD")
                string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
            endif(${flag_var} MATCHES "/MD")
        endforeach(flag_var)
    endif (MSVC AND protobuf_MSVC_STATIC_RUNTIME)
endif (protobuf_BUILD_SHARED_LIBS)

if (MSVC)
    # Build with multiple processes
    add_definitions(/MP)
    # MSVC warning suppressions
    add_definitions(
            /wd4018 # 'expression' : signed/unsigned mismatch
            /wd4065 # switch statement contains 'default' but no 'case' labels
            /wd4146 # unary minus operator applied to unsigned type, result still unsigned
            /wd4244 # 'conversion' conversion from 'type1' to 'type2', possible loss of data
            /wd4251 # 'identifier' : class 'type' needs to have dll-interface to be used by clients of class 'type2'
            /wd4267 # 'var' : conversion from 'size_t' to 'type', possible loss of data
            /wd4305 # 'identifier' : truncation from 'type1' to 'type2'
            /wd4307 # 'operator' : integral constant overflow
            /wd4309 # 'conversion' : truncation of constant value
            /wd4334 # 'operator' : result of 32-bit shift implicitly converted to 64 bits (was 64-bit shift intended?)
            /wd4355 # 'this' : used in base member initializer list
            /wd4506 # no definition for inline function 'function'
            /wd4800 # 'type' : forcing value to bool 'true' or 'false' (performance warning)
            /wd4996 # The compiler encountered a deprecated declaration.
    )
    # Allow big object
    add_definitions(/bigobj)
    string(REPLACE "/" "\\" PROTOBUF_SOURCE_WIN32_PATH ${protobuf_SOURCE_DIR})
    string(REPLACE "/" "\\" PROTOBUF_BINARY_WIN32_PATH ${protobuf_BINARY_DIR})
    configure_file(extract_includes.bat.in extract_includes.bat)

    # Suppress linker warnings about files with no symbols defined.
    set(CMAKE_STATIC_LINKER_FLAGS /ignore:4221)
endif (MSVC)

#get_filename_component(protobuf_source_dir ${protobuf_SOURCE_DIR} PATH)

include_directories(
        ${ZLIB_INCLUDE_DIRECTORIES}
        ${protobuf_BINARY_DIR}
        ${protobuf_source_dir}/src)

if (MSVC)
    # Add the "lib" prefix for generated .lib outputs.
    set(LIB_PREFIX lib)
else (MSVC)
    # When building with "make", "lib" prefix will be added automatically by
    # the build tool.
    set(LIB_PREFIX)
endif (MSVC)

if (protobuf_UNICODE)
    add_definitions(-DUNICODE -D_UNICODE)
endif (protobuf_UNICODE)

include(${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake/libprotobuf-lite.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake/libprotobuf.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake/libprotoc.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake/protoc.cmake)

target_compile_options(libprotobuf-lite
        PUBLIC  "-fno-wrapv"
        )
target_compile_options(libprotobuf
        PUBLIC  "-fno-wrapv"
        )
target_compile_options(libprotoc
        PUBLIC  "-fno-wrapv"
        )
target_compile_options(protoc
        PUBLIC  "-fno-wrapv"
        )
#if (protobuf_BUILD_TESTS)
#    include(${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake/tests.cmake)
#endif (protobuf_BUILD_TESTS)

if(protobuf_VERBOSE)
    message(STATUS "Protocol Buffers Configuring done")
endif()
