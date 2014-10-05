setlocal
SET PATH="C:\Program Files\PostgreSQL\9.3\bin";%PATH%
mkdir temp
set PGUSER=postgres
set PGPASSWORD=Password12!
psql -c "CREATE TABLESPACE tablespacetest LOCATION '%CD:\=/%/temp'"

