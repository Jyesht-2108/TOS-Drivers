-- School Transport Operations System (TOS) MVP - Seed Data
-- Mock data for local development and testing

-- ============================================================================
-- CLEAR EXISTING DATA (Optional - uncomment if needed)
-- ============================================================================
-- TRUNCATE TABLE notification_log, gps_logs, latest_bus_location, 
--   attendance_audit, attendance, trips, route_driver_assignment, 
--   route_students, routes, students, users CASCADE;

-- ============================================================================
-- TENANT CONFIGURATION
-- ============================================================================
-- All data belongs to a single tenant for this seed
-- Tenant ID: 'a0000000-0000-0000-0000-000000000001'

-- ============================================================================
-- 1. USERS
-- ============================================================================

-- Admin User
INSERT INTO users (id, role, tenant_id, phone, status, created_at, updated_at) VALUES
('10000000-0000-0000-0000-000000000001', 'ADMIN', 'a0000000-0000-0000-0000-000000000001', '+1234567890', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Driver Users
INSERT INTO users (id, role, tenant_id, phone, status, created_at, updated_at) VALUES
('20000000-0000-0000-0000-000000000001', 'DRIVER', 'a0000000-0000-0000-0000-000000000001', '+1234567891', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('20000000-0000-0000-0000-000000000002', 'DRIVER', 'a0000000-0000-0000-0000-000000000001', '+1234567892', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Parent Users
INSERT INTO users (id, role, tenant_id, phone, status, created_at, updated_at) VALUES
('30000000-0000-0000-0000-000000000001', 'PARENT', 'a0000000-0000-0000-0000-000000000001', '+1234567893', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('30000000-0000-0000-0000-000000000002', 'PARENT', 'a0000000-0000-0000-0000-000000000001', '+1234567894', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================================================
-- 2. STUDENTS
-- ============================================================================

-- Students for Parent A (2 students)
INSERT INTO students (id, tenant_id, name, parent_user_id, created_at, updated_at) VALUES
('40000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Emma Johnson', '30000000-0000-0000-0000-000000000001', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('40000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Liam Johnson', '30000000-0000-0000-0000-000000000001', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Students for Parent B (2 students)
INSERT INTO students (id, tenant_id, name, parent_user_id, created_at, updated_at) VALUES
('40000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Olivia Smith', '30000000-0000-0000-0000-000000000002', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('40000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Noah Smith', '30000000-0000-0000-0000-000000000002', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================================================
-- 3. ROUTES
-- ============================================================================

INSERT INTO routes (id, tenant_id, name, status, created_at, updated_at) VALUES
('50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Route A - Morning', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('50000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Route B - Evening', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================================================
-- 4. ROUTE STUDENTS
-- ============================================================================

-- Route A: Emma Johnson and Liam Johnson
INSERT INTO route_students (route_id, student_id, created_at) VALUES
('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', CURRENT_TIMESTAMP),
('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002', CURRENT_TIMESTAMP);

-- Route B: Olivia Smith and Noah Smith
INSERT INTO route_students (route_id, student_id, created_at) VALUES
('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000003', CURRENT_TIMESTAMP),
('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000004', CURRENT_TIMESTAMP);

-- ============================================================================
-- 5. ROUTE DRIVER ASSIGNMENT
-- ============================================================================

-- Driver 1 assigned to Route A
INSERT INTO route_driver_assignment (id, route_id, driver_user_id, active_from, active_to, created_at) VALUES
('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', CURRENT_DATE, NULL, CURRENT_TIMESTAMP);

-- Driver 2 assigned to Route B
INSERT INTO route_driver_assignment (id, route_id, driver_user_id, active_from, active_to, created_at) VALUES
('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', CURRENT_DATE, NULL, CURRENT_TIMESTAMP);

-- ============================================================================
-- SEED DATA SUMMARY
-- ============================================================================
-- Tenant: a0000000-0000-0000-0000-000000000001
-- Users: 1 Admin, 2 Drivers, 2 Parents (5 total)
-- Students: 4 (2 per parent)
-- Routes: 2 (Route A - Morning, Route B - Evening)
-- Route Students: 4 assignments (2 per route)
-- Driver Assignments: 2 (1 driver per route)
-- ============================================================================

-- Verification Queries (Optional - uncomment to run)
-- SELECT 'Users' as table_name, COUNT(*) as count FROM users
-- UNION ALL SELECT 'Students', COUNT(*) FROM students
-- UNION ALL SELECT 'Routes', COUNT(*) FROM routes
-- UNION ALL SELECT 'Route Students', COUNT(*) FROM route_students
-- UNION ALL SELECT 'Driver Assignments', COUNT(*) FROM route_driver_assignment;
