SET(PACKAGE osm2pgsql)
SET(PACKAGE_NAME osm2pgsql)

CMAKE_MINIMUM_REQUIRED(VERSION 3.0 FATAL_ERROR)

PROJECT(osm2pgsql)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

SET(DATA_DIR \".\")

OPTION(BUILD_TESTS "Build with tests" OFF)
SET(OSM2PGSQL_ROOT "" CACHE PATH "Location of osm2pgsql sources.")

if (NOT OSM2PGSQL_ROOT)
  set(OSM2PGSQL_ROOT osm2pgsql-cpp)
endif()

if (NOT EXISTS "${OSM2PGSQL_ROOT}")
  execute_process(COMMAND git clone https://github.com/openstreetmap/osm2pgsql.git  ${OSM2PGSQL_ROOT})
endif()
execute_process (COMMAND git describe WORKING_DIRECTORY ${OSM2PGSQL_ROOT} OUTPUT_VARIABLE PACKAGE_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Building osm2pgsql ${PACKAGE_VERSION}")

get_filename_component(OSM2PGSQL_ROOT ${OSM2PGSQL_ROOT} ABSOLUTE)

if (PACKAGE_VERSION VERSION_LESS 0.88.0)
	message(FATAL_ERROR "osm2pgsql sources of version 0.88.0 or greater required (found ${PACKAGE_VERSION})")
endif()

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE=Release)
endif()

# Just in case user installed RPMs from http://yum.postgresql.org/
list(APPEND PostgreSQL_ADDITIONAL_SEARCH_PATHS /usr/pgsql-9.3 /usr/pgsql-9.4)

if ( MSVC )
  add_definitions(-D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -wd4996)
  set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /STACK:30000000")
else()
  add_compile_options(-Wall)
endif()

option(EXTERNAL_LIBOSMIUM "Do not use the bundled libosmium" OFF)

#############################################################
# Detect available headers and set global compiler options
#############################################################

INCLUDE (CheckIncludeFiles)
INCLUDE (CheckFunctionExists)
INCLUDE (CheckTypeSize)

ADD_DEFINITIONS( -DOSM2PGSQL_DATADIR=${DATA_DIR} )
ADD_DEFINITIONS( -DFIXED_POINT )

CHECK_INCLUDE_FILES (termios.h HAVE_TERMIOS_H)
CHECK_INCLUDE_FILES (libgen.h HAVE_LIBGEN_H)
CHECK_INCLUDE_FILES (unistd.h HAVE_UNISTD_H)
CHECK_INCLUDE_FILES (sys/wait.h HAVE_SYS_WAIT_H)

if (WIN32)
  set(HAVE_LIBGEN_H FALSE)
endif()

CHECK_FUNCTION_EXISTS(lseek64 HAVE_LSEEK64)
CHECK_FUNCTION_EXISTS(posix_fallocate HAVE_POSIX_FALLOCATE)
CHECK_FUNCTION_EXISTS(posix_fadvise HAVE_POSIX_FADVISE)
CHECK_FUNCTION_EXISTS(sync_file_range HAVE_SYNC_FILE_RANGE)
CHECK_FUNCTION_EXISTS(fork HAVE_FORK)

CHECK_TYPE_SIZE("off_t" SIZEOF_OFF_T)

if (NOT WIN32 AND NOT APPLE AND NOT HAVE_LSEEK64 AND NOT SIZEOF_OFF_T EQUAL 8)
	message(FATAL_ERROR "Flat nodes cache requires a 64 bit capable seek")
endif()

#############################################################
# Find necessary libraries
#############################################################

if (NOT EXTERNAL_LIBOSMIUM)
	set(OSMIUM_INCLUDE_DIR "${OSM2PGSQL_ROOT}/contrib/libosmium")
endif()

find_package(Osmium REQUIRED COMPONENTS io geos proj)
include_directories(${OSMIUM_INCLUDE_DIRS})

find_package(Lua 5.2)
if ( LUA_LIBRARIES )
include_directories(${LUA_INCLUDE_DIR})
set(HAVE_LUA 1)
else()
  message(STATUS "lua libraries not found. You will NOT be able to use lua scripts for tag transform.")
endif()

# first try to find the version
find_package(Boost 1.48 REQUIRED COMPONENTS system chrono filesystem thread date_time)
include_directories(${Boost_INCLUDE_DIR})

find_package(PostgreSQL REQUIRED)
include_directories(${PostgreSQL_INCLUDE_DIRS})

find_package(Threads)

if(NOT CMAKE_COMPILER_IS_GNUCC AND WIN32)
  find_path(GETOPT_INCLUDE_DIR getopt.h)
  find_library(GETOPT_LIBRARY NAMES wingetopt )
  if (GETOPT_INCLUDE_DIR AND GETOPT_LIBRARY)
    include_directories(${GETOPT_INCLUDE_DIR})
  endif()
endif()

if (WIN32)
  SET(WIN_MORE_LIBS ws2_32)
endif()

############### Libraries are found now ########################


set (LIBS ${Boost_LIBRARIES} ${GETOPT_LIBRARY} ${PostgreSQL_LIBRARY} ${WIN_MORE_LIBS} ${OSMIUM_LIBRARIES})
if (LUA_LIBRARIES)
  list(APPEND LIBS ${LUA_LIBRARIES})
endif()

message("Libraries used to build: " ${LIBS})


#############################################################
# Build there library and executale file
#############################################################

set(HAVE_PTHREAD "${CMAKE_USE_PTHREADS_INIT}")
CONFIGURE_FILE(config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h)

if (NOT HAVE_UNISTD_H) 
   file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/unistd.h "// empty header\n")
endif()

include_directories(${CMAKE_CURRENT_BINARY_DIR}) # for generated files
include_directories(${OSM2PGSQL_ROOT}) # for
include_directories(${OSM2PGSQL_ROOT}/contrib/libosmium) # for

set(osm2pgsql_lib_SRC
	expire-tiles.cpp
	geometry-builder.cpp
	geometry-processor.cpp
	id-tracker.cpp
	middle.cpp
	middle-pgsql.cpp
	middle-ram.cpp
	node-persistent-cache.cpp
	node-ram-cache.cpp
	options.cpp
	osmdata.cpp
	output.cpp
	output-gazetteer.cpp
	output-multi.cpp
	output-null.cpp
	output-pgsql.cpp
	parse.cpp
	parse-o5m.cpp
	parse-osmium.cpp
	pgsql.cpp
	processor-line.cpp
	processor-point.cpp
	processor-polygon.cpp
	reprojection.cpp
	sprompt.cpp
	table.cpp
	taginfo.cpp
	tagtransform.cpp
	util.cpp
	wildcmp.cpp
)

foreach(src ${osm2pgsql_lib_SRC})
   list(APPEND osm2pgsql_lib_SOURCES ${OSM2PGSQL_ROOT}/${src})
endforeach()
list(APPEND osm2pgsql_lib_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/config.h)

SET (osm2pgsql_SRC 
        osm2pgsql.cpp
	geometry-builder.hpp
	expire-tiles.hpp
	middle-pgsql.hpp
	middle-ram.hpp
	middle.hpp
	node-persistent-cache.hpp
	node-ram-cache.hpp
	options.hpp
	osmdata.hpp
	osmtypes.hpp
	output-gazetteer.hpp
	output-null.hpp
	output-pgsql.hpp
	output.hpp
	osmdata.hpp
	parse.hpp
	parse-o5m.hpp
	parse-osmium.hpp
	pgsql.hpp
	reprojection.hpp
	sprompt.hpp
	table.hpp
	taginfo.hpp
	taginfo_impl.hpp
        tagtransform.hpp
	table.hpp
        wildcmp.hpp
	util.hpp
)

foreach(src ${osm2pgsql_SRC})
   list(APPEND osm2pgsql_SOURCES ${OSM2PGSQL_ROOT}/${src})
endforeach()
list(APPEND osm2pgsql_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/config.h)

add_library(osm2pgsql_lib STATIC ${osm2pgsql_lib_SOURCES})
set_target_properties(osm2pgsql_lib PROPERTIES OUTPUT_NAME osm2pgsql)

add_executable(osm2pgsql ${osm2pgsql_SOURCES})
target_link_libraries(osm2pgsql_lib ${LIBS})
target_link_libraries(osm2pgsql osm2pgsql_lib ${LIBS})

set(EXE_LOCATION $<TARGET_FILE:osm2pgsql>)


# Copy executable to source folder for Python testing
add_custom_command(TARGET osm2pgsql POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${EXE_LOCATION} ${OSM2PGSQL_ROOT})


#############################################################
# Build tests
#############################################################

if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

# Emulate make check
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} -VV)


#############################################################
# Install
#############################################################

install(TARGETS osm2pgsql DESTINATION bin)
install(TARGETS osm2pgsql_lib DESTINATION lib)
