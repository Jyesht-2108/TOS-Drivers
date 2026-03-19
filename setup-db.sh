#!/bin/bash

echo "========================================="
echo "TOS Database Setup Script"
echo "========================================="
echo ""

echo "Step 1: Dropping existing database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS tos_db;"

echo ""
echo "Step 2: Creating database..."
sudo -u postgres psql -c "CREATE DATABASE tos_db;"

echo ""
echo "Step 3: Running schema..."
sudo -u postgres psql -d tos_db -f backend/db/schema-unified.sql

echo ""
echo "Step 4: Loading seed data..."
sudo -u postgres psql -d tos_db -f backend/db/seeds-unified.sql

echo ""
echo "Step 5: Verifying setup..."
echo ""
echo "All Users:"
sudo -u postgres psql -d tos_db -c "SELECT name, phone, role FROM users ORDER BY role, name;"

echo ""
echo "All Drivers:"
sudo -u postgres psql -d tos_db -c "SELECT u.name, u.phone, d.vehicle_number, r.name as route FROM users u JOIN drivers d ON d.user_id = u.id LEFT JOIN route_driver_assignment rda ON rda.driver_id = u.id AND rda.active_to IS NULL LEFT JOIN routes r ON r.id = rda.route_id ORDER BY u.name;"

echo ""
echo "Driver 9876543210 Details:"
sudo -u postgres psql -d tos_db -c "SELECT u.id as user_id, u.name, u.phone, d.vehicle_number, r.id as route_id, r.name as route_name FROM users u JOIN drivers d ON d.user_id = u.id LEFT JOIN route_driver_assignment rda ON rda.driver_id = u.id AND rda.active_to IS NULL LEFT JOIN routes r ON r.id = rda.route_id WHERE u.phone = '9876543210';"

echo ""
echo "========================================="
echo "✅ Database setup complete!"
echo "========================================="
echo ""
echo "Driver Login Details:"
echo "  Phone: 9876543210"
echo "  Name: Michael Kumar"
echo "  User ID: 20000000-0000-0000-0000-000000000003"
echo "  Route ID: 50000000-0000-0000-0000-000000000003"
echo "  Vehicle: BUS-003"
echo ""
echo "Next Steps:"
echo "  1. Start backend: cd backend && mvn spring-boot:run"
echo "  2. Test login with phone: 9876543210"
echo "  3. Use User ID for SSE connection"
echo "  4. Use User ID + Route ID for starting trip"
echo ""
