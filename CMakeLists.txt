SET(PACKAGE osm2pgsql)
SET(PACKAGE_NAME osm2pgsql)

CMAKE_MINIMUM_REQUIRED(VERSION 2.8 FATAL_ERROR)

PROJECT(osm2pgsql)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

SET(DATA_DIR \".\")
SET(PACKAGE_VERSION \"0.85-cpp-win-cmake\")

OPTION(USE64BITID "Build with 64 bit OSM ID" ON)
OPTION(BUILD_PBF "Build with PBF format support" ON)
OPTION(BUILD_TESTS "Build with tests" OFF)
SET(OSM2PGSQL_ROOT "" CACHE PATH "Location of osm2pgsql sources.")

if (NOT OSM2PGSQL_ROOT)
  set(OSM2PGSQL_ROOT osm2pgsql-cpp)
endif()

if (NOT EXISTS OSM2PGSQL_ROOT)
  execute_process(COMMAND git clone https://github.com/openstreetmap/osm2pgsql.git  ${OSM2PGSQL_ROOT})
endif()

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE=Release)
endif()

# Just in case user installed RPMs from http://yum.postgresql.org/
list(APPEND PostgreSQL_ADDITIONAL_SEARCH_PATHS /usr/pgsql-9.3)

if ( MSVC )
  add_definitions(-D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -wd4996)
  set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /STACK:30000000")
else()
  add_compile_options(-Wall)
endif()

#############################################################
# Detect available headers and set global compiler options
#############################################################

INCLUDE (CheckIncludeFiles)
INCLUDE (CheckFunctionExists)
INCLUDE (CheckTypeSize)

ADD_DEFINITIONS( -DOSM2PGSQL_DATADIR=${DATA_DIR} )
ADD_DEFINITIONS( -DVERSION=${PACKAGE_VERSION} )

CHECK_INCLUDE_FILES (termios.h HAVE_TERMIOS_H)
CHECK_INCLUDE_FILES (libgen.h HAVE_LIBGEN_H)
CHECK_INCLUDE_FILES (unistd.h HAVE_UNISTD_H)

if (WIN32)
  set(HAVE_LIBGEN_H FALSE)
endif()

CHECK_FUNCTION_EXISTS(lseek64, HAVE_LSEEK64)
CHECK_FUNCTION_EXISTS(posix_fallocate, HAVE_POSIX_FALLOCATE)
CHECK_FUNCTION_EXISTS(posix_fadvice, HAVE_POSIX_FADVICE)
CHECK_FUNCTION_EXISTS(sync_file_range, HAVE_SYNC_FILE_RANGE)
CHECK_FUNCTION_EXISTS(fork, HAVE_FORK)

CHECK_TYPE_SIZE("off_t" SIZEOF_OFF_T)

if (USE64BITID)
   ADD_DEFINITIONS( -DOSMID64 )
endif()

#############################################################
# Find necessary libraries
#############################################################

find_package(ZLIB)
find_package(Threads)

if ( ZLIB_FOUND )
    include_directories(${ZLIB_INCLUDE_DIR})
else(ZLIB)
    MARK_AS_ADVANCED(CLEAR ZLIB_LIBRARY ZLIB_INCLUDE_DIR)
    message(FATAL_ERROR "Please, specify the ZLIB includes directory and the library file")
endif( ZLIB_FOUND )

find_package(Protobuf REQUIRED)
if ( BUILD_PBF )
  if ( PROTOBUF_INCLUDE_DIR AND PROTOBUF_LIBRARY )
    FIND_LIBRARY(PROTOBUF_C_LIBRARY protobuf-c PATH_SUFFIXES lib lib64 )
    FIND_PROGRAM(PROTOBUF_C_EXECUTABLE NAMES protoc-c DOC "The Protobuf-C Compiler" )
    FIND_PATH(PROTOBUF_C_INCLUDE protobuf-c/protobuf-c.h  PATH_SUFFIXES "google")

    if (NOT PROTOBUF_C_INCLUDE)
      MARK_AS_ADVANCED(CLEAR PROTOBUF_C_INCLUDE)
      message(FATAL_ERROR "Please specify the Protobuf-C include files location")
    endif()

    if (NOT PROTOBUF_C_LIBRARY)
      MARK_AS_ADVANCED(CLEAR PROTOBUF_C_LIBRARY)
      message(FATAL_ERROR "Please specify the Protobuf-C library location")
    endif()

    if (NOT PROTOBUF_C_EXECUTABLE)
      MARK_AS_ADVANCED(CLEAR PROTOBUF_C_EXECUTABLE)
      message(FATAL_ERROR "Please specify the protoc-c executable location")
    endif()

    set(PBF_READER_SOURCES ${OSM2PGSQL_ROOT}/parse-pbf.cpp protobuf/fileformat.pb-c.c protobuf/osmformat.pb-c.c)

    add_custom_command(OUTPUT protobuf/fileformat.pb-c.c protobuf/osmformat.pb-c.c
      COMMAND ${PROTOBUF_C_EXECUTABLE} -I${OSM2PGSQL_ROOT} ${OSM2PGSQL_ROOT}/protobuf/fileformat.proto --c_out=${CMAKE_BINARY_DIR}
      COMMAND ${PROTOBUF_C_EXECUTABLE} -I${OSM2PGSQL_ROOT} ${OSM2PGSQL_ROOT}/protobuf/osmformat.proto --c_out=${CMAKE_BINARY_DIR}
    )

    include_directories(${PROTOBUF_C_INCLUDE})
    include_directories(${CMAKE_BINARY_DIR}/protobuf)
    ADD_DEFINITIONS(-DBUILD_READER_PBF)
  else()
    MARK_AS_ADVANCED(CLEAR PROTOBUF_INCLUDE_DIR PROTOBUF_LITE_LIBRARY )
    message(FATAL_ERROR "Please specify the Google PROTOBUF library dir")
  endif()
endif()

find_package(LibXml2)
if ( LIBXML2_LIBRARIES )
  include_directories(${LIBXML2_INCLUDE_DIR})
else()
  MARK_AS_ADVANCED(CLEAR LIBXML2_INCLUDE_DIR LIBXML2_LIBRARIES)
  message(FATAL_ERROR "Please, specify the LibXML2 library dir")
endif()

find_package(BZip2)
include_directories(${BZIP2_INCLUDE_DIR})

find_package(Lua52)
if ( LUA_LIBRARIES )
include_directories(${LUA_INCLUDE_DIR})
set(HAVE_LUA 1)
else()
  MARK_AS_ADVANCED(CLEAR LUA_LIBRARIES LUA_LIBRARY)
  message(FATAL_ERROR "Please, specify the Lua libraries and include dir")
endif()

# first try to find the version
find_package(Boost 1.48 COMPONENTS system chrono atomic thread date_time filesystem REQUIRED)
include_directories(${Boost_INCLUDE_DIR})

find_package(PostgreSQL)
if ( PostgreSQL_FOUND )
  include_directories(${PostgreSQL_INCLUDE_DIRS})
else()
  message(FATAL_ERROR "PostgreSQL not found, please install and give the path to CMAKE")
endif()

##### Find GEOS Library 
find_path(GEOS_INCLUDE_DIR geos/geom.h)
find_library(GEOS_LIBRARY NAMES geos)
if(GEOS_INCLUDE_DIR AND GEOS_LIBRARY)
  MESSAGE( STATUS "GEOS library found")
  SET(GEOS_FOUND 1)
  include_directories(${GEOS_INCLUDE_DIR})
else()
  MESSAGE( STATUS "GEOS library not found")
endif()
#####

##### Find Proj.4 Library 
find_path(PROJ_INCLUDE_DIR proj_api.h)
find_library(PROJ_LIBRARY NAMES proj)
if(PROJ_INCLUDE_DIR AND PROJ_LIBRARY)
  MESSAGE( STATUS "PROJ library found")
  SET(GEOS_FOUND 1)
  include_directories(${PROJ_INCLUDE_DIR})
else()
  MESSAGE( STATUS "PROJ library not found")
endif()
#####

if(NOT CMAKE_COMPILER_IS_GNUCC AND WIN32)
  find_path(GETOPT_INCLUDE_DIR getopt.h)
  find_library(GETOPT_LIBRARY NAMES wingetopt )
  if (GETOPT_INCLUDE_DIR AND GETOPT_LIBRARY)
    include_directories(${GETOPT_INCLUDE_DIR})
  endif()
endif()

if (BUILD_PBF)
  if (WIN32)
   SET(WIN_MORE_LIBS ws2_32)
  endif()
endif()


############### Libraries are found now ########################

set (LIBS ${Boost_LIBRARIES} ${GEOS_LIBRARY} ${PROJ_LIBRARY} 
  ${LIBXML2_LIBRARIES} ${GETOPT_LIBRARY} ${PostgreSQL_LIBRARY} 
  ${LUA_LIBRARY} ${BZIP2_LIBRARY} ${PROTOBUF_C_LIBRARY} ${WIN_MORE_LIBS} ${ZLIB_LIBRARIES} )

message("Libraries used to build: " ${LIBS})


#############################################################
# Build there library and executale file
#############################################################

CONFIGURE_FILE(config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h)

if (NOT HAVE_UNISTD_H) 
   file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/unistd.h "// empty header\n")
endif()

include_directories(${CMAKE_CURRENT_BINARY_DIR}) # for generated files
include_directories(${OSM2PGSQL_ROOT}) # for

set(osm2pgsql_lib_SRC
	UTF8sanitizer.cpp
	binarysearcharray.cpp
	buffer.cpp
	expire-tiles.cpp
	geometry-builder.cpp
	geometry-processor.cpp
	id-tracker.cpp
	input.cpp
	keyvals.cpp
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
	parse-primitive.cpp
	parse-xml2.cpp
	pgsql.cpp
	pgsql-id-tracker.cpp
	processor-line.cpp
	processor-point.cpp
	processor-polygon.cpp
	rb.cpp
	reprojection.cpp
	sprompt.cpp
	table.cpp
	taginfo.cpp
	tagtransform.cpp
	text-tree.cpp
	util.cpp
	wildcmp.cpp
)

foreach(src ${osm2pgsql_lib_SRC})
   list(APPEND osm2pgsql_lib_SOURCES ${OSM2PGSQL_ROOT}/${src})
endforeach()
list(APPEND osm2pgsql_lib_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/config.h ${PBF_READER_SOURCES})

SET (osm2pgsql_SRC 
   osm2pgsql.cpp
   binarysearcharray.hpp
	geometry-builder.hpp
	expire-tiles.hpp
	input.hpp
	keyvals.hpp
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
	parse.hpp
	parse-o5m.hpp
	parse-pbf.hpp
	parse-primitive.hpp
	parse-xml2.hpp
	pgsql.hpp
	rb.hpp
	reprojection.hpp
	sanitizer.hpp
	sprompt.hpp
	table.hpp
	text-tree.hpp
	util.hpp
)

foreach(src ${osm2pgsql_SRC})
   list(APPEND osm2pgsql_SOURCES ${OSM2PGSQL_ROOT}/${src})
endforeach()
list(APPEND osm2pgsql_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/config.h ${PBF_READER_SOURCES})

add_library(osm2pgsql_lib STATIC ${osm2pgsql_lib_SOURCES})
set_target_properties(osm2pgsql_lib PROPERTIES OUTPUT_NAME osm2pgsql)

add_executable(osm2pgsql ${osm2pgsql_SOURCES})
target_link_libraries(osm2pgsql_lib ${LIBS})
target_link_libraries(osm2pgsql osm2pgsql_lib ${LIBS})

get_property(EXE_LOCATION TARGET osm2pgsql PROPERTY LOCATION)

# Copy executable to source folder for Python testing
add_custom_command(TARGET osm2pgsql POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${EXE_LOCATION} ${OSM2PGSQL_ROOT})


#############################################################
# Build tests
#############################################################

if(BUILD_TESTS)
  enable_testing()

  add_library(common-pg STATIC ${OSM2PGSQL_ROOT}/tests/common-pg.cpp)
  add_library(middle-tests STATIC ${OSM2PGSQL_ROOT}/tests/middle-tests.cpp)

  set(TESTS 
    test-parse-xml2
    test-middle-ram
    test-middle-pgsql
    test-output-multi-line
    test-output-multi-point
    test-output-multi-point-multi-table
    test-output-multi-polygon
    test-pgsql-escape
    test-parse-options
    test-expire-tiles
  )

  set(DART_TESTING_TIMEOUT 2000)
  include(Dart)


  get_filename_component(srcdir ${OSM2PGSQL_ROOT} ABSOLUTE)

  foreach(test_name ${TESTS})
    add_executable(${test_name} ${OSM2PGSQL_ROOT}/tests/${test_name}.cpp)
    target_link_libraries(${test_name} osm2pgsql_lib common-pg middle-tests)
    add_test(NAME ${test_name} COMMAND ${test_name}
         WORKING_DIRECTORY ${srcdir})
  endforeach(test_name)

  add_test(NAME regression-test-pbf COMMAND python tests/regression-test.py -f tests/liechtenstein-2013-08-03.osm.pbf 
         WORKING_DIRECTORY ${srcdir})
  add_test(NAME regression-test-bz2 COMMAND python tests/regression-test.py -f tests/liechtenstein-2013-08-03.osm.bz2 
         WORKING_DIRECTORY ${srcdir})
  set_tests_properties(test-parse-xml2 PROPERTIES ENVIRONMENT srcdir=${srcdir})
endif()

# Emulate make check
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} -VV)


#############################################################
# Install
#############################################################

install(TARGETS osm2pgsql DESTINATION bin)
install(TARGETS osm2pgsql_lib DESTINATION lib)
