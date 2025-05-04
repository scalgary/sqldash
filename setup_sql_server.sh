#!/bin/bash

# Variables
IMAGE="mcr.microsoft.com/mssql/server:2022-latest" # Docker image to use
CONTAINER="sql-dev"
PASSWORD="<2Indians_1CowBoys>" # Must include uppercase, lowercase, digit, and special character
BAK_LOCAL_PATH="sql_backup/AdventureWorks2019.bak" # Path to .bak file on the host
BAK_NAME="AdventureWorks2019.bak"
BAK_CONTAINER_PATH="/var/opt/mssql/backup/$BAK_NAME"
DB_NAME="AdventureWorks2019" # See: https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

# Step 1: Cleanup (if container already exists)
echo "🧹 Removing old container (if any)..."
docker rm -f $CONTAINER 2>/dev/null

# Step 2: Download SQL Server Docker image
echo "⬇️ Downloading SQL Server Docker image..."
docker pull --platform linux/amd64 $IMAGE

# Step 3: Create and start the container
echo "🚀 Starting SQL Server container..."
docker run --platform linux/amd64 -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$PASSWORD" \
  -p 1433:1433 --name $CONTAINER -d $IMAGE

# Wait for SQL Server to fully start
echo "⏳ Waiting for SQL Server to start..."
sleep 15

# Step 4: Create backup folder inside the container
echo "📁 Creating backup folder in container..."
docker exec -it $CONTAINER mkdir -p /var/opt/mssql/backup

# Step 5: Copy the .bak file into the container
echo "📥 Copying .bak file into the container..."
docker cp $BAK_LOCAL_PATH $CONTAINER:$BAK_CONTAINER_PATH

# Step 6: Restore the database
echo "🧱 Restoring the database..."
docker exec -i $CONTAINER $SQLCMD -S localhost -U SA -P "$PASSWORD" -C -Q "
RESTORE DATABASE [$DB_NAME]
FROM DISK = '$BAK_CONTAINER_PATH'
WITH MOVE 'AdventureWorks2019' TO '/var/opt/mssql/data/${DB_NAME}.mdf',
     MOVE 'AdventureWorks2019_log' TO '/var/opt/mssql/data/${DB_NAME}_log.ldf',
     REPLACE;
"

# Step 7: Run a test query
echo "🔍 Running a test query..."
docker exec -i $CONTAINER $SQLCMD -S localhost -U SA -P "$PASSWORD" -C -Q "
USE [$DB_NAME];
SELECT TOP 10 p.FirstName, p.LastName, e.EmailAddress
FROM Person.Person p
JOIN Person.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID;
"

echo "✅ Done! Database restored and query executed."