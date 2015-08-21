This code allows to compile osm2pgsql using [CMake](http://www.cmake.org). To get this
working you need osm2pgsql (at least verion 0.88.0), it's dependencies, and CMake
(at least version 3.0).

To build osm2pgsql using the bundled copy of libosmium do it like this:

    mkdir build
    cd build
    cmake -D OSM2PGSQL_ROOT=/path/to/osm2pgsql /path/to/osm2pgsql-cmake

If you want to use a different libosmium version do it like this instead:

    mkdir build
    cd build
    cmake -D OSM2PGSQL_ROOT=/path/to/osm2pgsql -D EXTERNAL_LIBOSMIUM=On \
          -D CMAKE_PREFIX_PATH=/path/to/osmium /path/to/osm2pgsql-cmake

In this case the osm.hpp of libosmium would be in
/path/to/osmium/include/osmium/osm.hpp.

After cmake finishes just run

    make
