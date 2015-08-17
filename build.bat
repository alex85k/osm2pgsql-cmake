call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" x86_amd64
set "PSQL_ROOT=C:\Program Files\PostgreSQL\9.4"

set PGUSER=postgres
set PGPASSWORD=admin
set BOOST_ROOT=d:\boost
set PREFIX=d:\libs19r
set VARIANT=Release
set OSM2PGSQL=osm2pgsql-cpp

set "CMAKE_PREFIX_PATH=%PREFIX%;%PSQL_ROOT%"

cmake -G "NMake Makefiles" -DBOOST_ROOT=%BOOST_ROOT% -DCMAKE_BUILD_TYPE=%VARIANT% -DCMAKE_INSTALL_PREFIX=%PREFIX% -DBoost_USE_STATIC_LIBS=ON -DBUILD_TESTS=ON  -DBUILD_TESTS=ON -DBoost_ADDITIONAL_VERSIONS=1.57;1.58;1.59
if ERRORLEVEL 1 exit /b 1
nmake
if ERRORLEVEL 1 exit /b 1

mkdir osm2pgsql-cpp-bin

  copy /y %OSM2PGSQL%\*.exe osm2pgsql-cpp-bin
  copy /y %OSM2PGSQL%\osm2pgsql-cpp\*.style osm2pgsql-cpp-bin
  copy /y %OSM2PGSQL%\osm2pgsql-cpp\style.lua osm2pgsql-cpp-bin
  copy /y %PREFIX%\bin\libxml2.dll osm2pgsql-cpp-bin
  copy /y %PREFIX%\bin\lua.dll osm2pgsql-cpp-bin
  copy /y %PREFIX%\bin\geos.dll osm2pgsql-cpp-bin
  copy /y "%PSQL_ROOT%\bin\libpq.dll" osm2pgsql-cpp-bin
  copy /y "%PSQL_ROOT%\bin\libintl-8.dll" osm2pgsql-cpp-bin
  copy /y "%PSQL_ROOT%\bin\libeay32.dll" osm2pgsql-cpp-bin
  copy /y "%PSQL_ROOT%\bin\ssleay32.dll" osm2pgsql-cpp-bin

echo "Running tests - see build_testing.log..."
set PATH=%CD%\osm2pgsql-cpp-bin;%PATH%
copy /y osm2pgsql.exe %OSM2PGSQL%\
ctest -VV >build_testing.log 2>&1
if ERRORLEVEL 1 exit /b 1
echo "Tests passed"
