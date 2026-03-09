#!/bin/bash

# Reset database script with unified schema
# This drops and recreates the database with the unified schema

set -e

DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="tos_db"
DB_PASSWORD="123456"

echo "🗑️  Dropping existing database..."

# Drop and recreate database
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d postgres << EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
EOF

echo "✅ Database dropped and recreated"
echo ""
echo "📥 Loading unified schema..."

# Load unified schema
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f schema-unified.sql

echo "✅ Schema loaded"
echo ""
echo "📥 Loading unified seed data..."

# Load unified seed data
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f seeds-unified.sql

echo ""
echo "✅ Database reset complete with unified schema!"
echo ""
echo "📊 Current data counts:"

PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME << EOF
SELECT 'Tenants' as table_name, COUNT(*) as count FROM tenants
UNION ALL SELECT 'Users', COUNT(*) FROM users
UNION ALL SELECT 'Drivers', COUNT(*) FROM drivers
UNION ALL SELECT 'Students', COUNT(*) FROM students
UNION ALL SELECT 'Student Parents', COUNT(*) FROM student_parents
UNION ALL SELECT 'Routes', COUNT(*) FROM routes
UNION ALL SELECT 'Route Students', COUNT(*) FROM route_students
UNION ALL SELECT 'Driver Assignments', COUNT(*) FROM route_driver_assignment;
EOF

echo ""
echo "🔑 Test credentials for driver app:"
echo "   Driver 1: +1234567891 (John Anderson - Route A)"
echo "   Driver 2: +1234567892 (Sarah Thompson - Route B)"
