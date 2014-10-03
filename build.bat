call "%VS120COMNTOOLS%\..\..\VC\vcvarsall.bat" x86_amd64
set "PSQL_ROOT=C:\Program Files\PostgreSQL\9.3"
set PGUSER=postgres
set PGPASSWORD=
set BOOST_ROOT=c:\boost
set PREFIX=d:\libs18d
set VARIANT=Debug
set OSM2PGSQL=osm2pgsql-cpp

set "CMAKE_PREFIX_PATH=%PREFIX%;%PSQL_ROOT%"

cmake -G "NMake Makefiles" -DBOOST_ROOT=%BOOST_ROOT% -DCMAKE_BUILD_TYPE=%VARIANT% -DCMAKE_INSTALL_PREFIX=%PREFIX% -DBoost_USE_STATIC_LIBS=ON -DBUILD_PBF=ON -DBUILD_TESTS=ON
if ERRORLEVEL 1 exit /b 1
nmake
if ERRORLEVEL 1 exit /b 1

mkdir osm2pgsql-cpp-bin
copy /y *.exe osm2pgsql-cpp-bin
copy /y %OSM2PGSQL%\default.style osm2pgsql-cpp-bin
copy /y %OSM2PGSQL%\style.lua osm2pgsql-cpp-bin
copy /y %PREFIX%\bin\libxml2.dll osm2pgsql-cpp-bin

copy /y %PREFIX%\bin\lua.dll osm2pgsql-cpp-bin
copy /y %PREFIX%\bin\geos.dll osm2pgsql-cpp-bin
copy /y "%PSQL_ROOT%\bin\libpq.dll" osm2pgsql-cpp-bin
copy /y "%PSQL_ROOT%\bin\libintl-8.dll" osm2pgsql-cpp-bin
copy /y "%PSQL_ROOT%\bin\libeay32.dll" osm2pgsql-cpp-bin
copy /y "%PSQL_ROOT%\bin\ssleay32.dll" osm2pgsql-cpp-bin

echo "Running tests - see build_testing.log..."
set PATH=%CD%\osm2pgsql-cpp-bin;%PATH%
rem %CD%;%PREFIX%\bin;C:\Program Files\PostgreSQL\9.3;%PATH%
copy /y osm2pgsql.exe %OSM2PGSQL%\
ctest -VV >build_testing.log 2>&1
if ERRORLEVEL 1 exit /b 1
echo "Tests passed"
