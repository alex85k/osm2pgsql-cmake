add_library(common-pg STATIC ${OSM2PGSQL_ROOT}/tests/common-pg.cpp)
add_library(middle-tests STATIC ${OSM2PGSQL_ROOT}/tests/middle-tests.cpp)

set(TESTS
	test-expire-tiles
	test-hstore-match-only
	test-middle-flat
	test-middle-pgsql
	test-middle-ram
	test-options-database
	test-options-parse
	test-output-multi-line-storage
	test-output-multi-line
	test-output-multi-point-multi-table
	test-output-multi-point
	test-output-multi-poly-trivial
	test-output-multi-polygon
	test-output-multi-tags
	test-output-pgsql-schema
	test-output-pgsql-tablespace
	test-output-pgsql-z_order
	test-output-pgsql
	test-parse-xml2
	test-pgsql-escape
)

set(DART_TESTING_TIMEOUT 2000)
include(Dart)

foreach(test_name ${TESTS})
  add_executable(${test_name} ${OSM2PGSQL_ROOT}/tests/${test_name}.cpp)
  target_link_libraries(${test_name} osm2pgsql_lib common-pg middle-tests)
  add_test(NAME ${test_name} COMMAND ${test_name}
           WORKING_DIRECTORY ${OSM2PGSQL_ROOT})
endforeach(test_name)

add_test(NAME regression-test-pbf COMMAND python tests/regression-test.py -f tests/liechtenstein-2013-08-03.osm.pbf
         WORKING_DIRECTORY ${OSM2PGSQL_ROOT})
