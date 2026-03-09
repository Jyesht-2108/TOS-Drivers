-- Unified Seed Data for TOS (Transport Operations System)
-- Combines data for Driver App testing
-- Created: 2026-03-09

-- ============================================================================
-- PART 1: TENANTS
-- ============================================================================

INSERT INTO tenants (id, name, email, phone, address, status, created_at, updated_at) VALUES
('a0000000-0000-0000-0000-000000000001', 'Springfield Elementary School', 'admin@springfield-school.edu', '+1234567890', '123 School Street, Springfield', 'ACTIVE', NOW(), NOW());

-- ============================================================================
-- PART 2: USERS
-- ============================================================================

-- Admin User
INSERT INTO users (id, tenant_id, email, password_hash, name, phone, role, status, created_at, updated_at) VALUES
('10000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'admin@springfield-school.edu', '$2a$10$dummyhash', 'Admin User', '+1234567890', 'ADMIN', 'ACTIVE', NOW(), NOW());

-- Driver Users
INSERT INTO users (id, tenant_id, email, password_hash, name, phone, role, status, created_at, updated_at) VALUES
('20000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'driver1@springfield-school.edu', '$2a$10$dummyhash', 'John Anderson', '+1234567891', 'DRIVER', 'ACTIVE', NOW(), NOW()),
('20000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'driver2@springfield-school.edu', '$2a$10$dummyhash', 'Sarah Thompson', '+1234567892', 'DRIVER', 'ACTIVE', NOW(), NOW());

-- Parent Users
INSERT INTO users (id, tenant_id, email, password_hash, name, phone, role, status, created_at, updated_at) VALUES
('30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'parent1@example.com', '$2a$10$dummyhash', 'Robert Johnson', '+1234567893', 'PARENT', 'ACTIVE', NOW(), NOW()),
('30000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'parent2@example.com', '$2a$10$dummyhash', 'Mary Smith', '+1234567894', 'PARENT', 'ACTIVE', NOW(), NOW());

-- ============================================================================
-- PART 3: DRIVERS (Extended Info)
-- ============================================================================

INSERT INTO drivers (id, user_id, tenant_id, license_number, license_expiry, vehicle_number, vehicle_type, status, created_at, updated_at) VALUES
('d0000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'DL123456789', '2027-12-31', 'BUS-001', 'School Bus', 'ACTIVE', NOW(), NOW()),
('d0000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'DL987654321', '2028-06-30', 'BUS-002', 'School Bus', 'ACTIVE', NOW(), NOW());

-- ============================================================================
-- PART 4: STUDENTS
-- ============================================================================

INSERT INTO students (id, tenant_id, name, grade, section, roll_number, date_of_birth, gender, blood_group, address, status, created_at, updated_at) VALUES
('40000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Emma Johnson', 'Grade 5', 'A', '501', '2015-03-15', 'FEMALE', 'O+', '456 Oak Street, Springfield', 'ACTIVE', NOW(), NOW()),
('40000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Liam Johnson', 'Grade 3', 'B', '302', '2017-07-22', 'MALE', 'O+', '456 Oak Street, Springfield', 'ACTIVE', NOW(), NOW()),
('40000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Olivia Smith', 'Grade 4', 'A', '401', '2016-11-08', 'FEMALE', 'A+', '789 Maple Avenue, Springfield', 'ACTIVE', NOW(), NOW()),
('40000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Noah Smith', 'Grade 6', 'C', '603', '2014-05-19', 'MALE', 'A+', '789 Maple Avenue, Springfield', 'ACTIVE', NOW(), NOW());

-- ============================================================================
-- PART 5: STUDENT-PARENT RELATIONSHIPS
-- ============================================================================

-- Emma and Liam Johnson -> Robert Johnson (Father)
INSERT INTO student_parents (student_id, parent_user_id, relationship, is_primary, created_at) VALUES
('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'FATHER', true, NOW()),
('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'FATHER', true, NOW());

-- Olivia and Noah Smith -> Mary Smith (Mother)
INSERT INTO student_parents (student_id, parent_user_id, relationship, is_primary, created_at) VALUES
('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000002', 'MOTHER', true, NOW()),
('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000002', 'MOTHER', true, NOW());

-- ============================================================================
-- PART 6: ROUTES
-- ============================================================================

INSERT INTO routes (id, tenant_id, name, status, created_at, updated_at) VALUES
('50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Route A - Morning', 'ACTIVE', NOW(), NOW()),
('50000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Route B - Evening', 'ACTIVE', NOW(), NOW());

-- ============================================================================
-- PART 7: ROUTE STUDENTS
-- ============================================================================

-- Route A: Emma Johnson and Liam Johnson
INSERT INTO route_students (route_id, student_id, created_at) VALUES
('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', NOW()),
('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002', NOW());

-- Route B: Olivia Smith and Noah Smith
INSERT INTO route_students (route_id, student_id, created_at) VALUES
('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000003', NOW()),
('50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000004', NOW());

-- ============================================================================
-- PART 8: ROUTE DRIVER ASSIGNMENTS
-- ============================================================================

-- Driver 1 (John Anderson) assigned to Route A
INSERT INTO route_driver_assignment (id, route_id, driver_id, active_from, active_to, created_at) VALUES
('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', CURRENT_DATE, NULL, NOW());

-- Driver 2 (Sarah Thompson) assigned to Route B
INSERT INTO route_driver_assignment (id, route_id, driver_id, active_from, active_to, created_at) VALUES
('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', CURRENT_DATE, NULL, NOW());

-- ============================================================================
-- SEED DATA SUMMARY
-- ============================================================================
-- Tenant: Springfield Elementary School
-- Users: 1 Admin, 2 Drivers, 2 Parents (5 total)
-- Drivers: 2 (with extended info)
-- Students: 4 (2 per parent, 2 per route)
-- Routes: 2 (Route A - Morning, Route B - Evening)
-- Route Students: 4 assignments (2 per route)
-- Driver Assignments: 2 (1 driver per route)
-- ============================================================================

-- Verification Queries (Optional - uncomment to run)
-- SELECT 'Tenants' as table_name, COUNT(*) as count FROM tenants
-- UNION ALL SELECT 'Users', COUNT(*) FROM users
-- UNION ALL SELECT 'Drivers', COUNT(*) FROM drivers
-- UNION ALL SELECT 'Students', COUNT(*) FROM students
-- UNION ALL SELECT 'Student Parents', COUNT(*) FROM student_parents
-- UNION ALL SELECT 'Routes', COUNT(*) FROM routes
-- UNION ALL SELECT 'Route Students', COUNT(*) FROM route_students
-- UNION ALL SELECT 'Driver Assignments', COUNT(*) FROM route_driver_assignment;
