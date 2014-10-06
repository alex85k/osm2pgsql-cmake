setlocal
SET PATH="C:\Program Files\PostgreSQL\9.3\bin";%PATH%
set PGUSER=postgres
set PGPASSWORD=Password12!
mkdir temp
cacls temp /T /E /G Users:F
cacls temp /T /E /G "Network Service":F
cacls temp /T /E /G postgres:F
psql -c "CREATE TABLESPACE tablespacetest LOCATION '%CD:\=/%/temp'"

