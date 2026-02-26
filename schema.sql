-- School Transport Operations System (TOS) MVP - PostgreSQL Schema
-- Generated for multi-tenant school transport management

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

CREATE TYPE trip_type_enum AS ENUM ('PICKUP', 'DROP');
CREATE TYPE trip_status_enum AS ENUM ('ACTIVE', 'ENDED');
CREATE TYPE attendance_status_enum AS ENUM ('PRESENT', 'ABSENT');
CREATE TYPE notification_status_enum AS ENUM ('QUEUED', 'SENT', 'FAILED');
CREATE TYPE notification_type_enum AS ENUM ('TRIP_START');

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role VARCHAR(50) NOT NULL,
    tenant_id UUID NOT NULL,
    phone VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_phone ON users(phone);

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    parent_user_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_students_tenant_id ON students(tenant_id);
CREATE INDEX idx_students_parent_user_id ON students(parent_user_id);

-- Routes table
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_routes_tenant_id ON routes(tenant_id);
CREATE INDEX idx_routes_status ON routes(status);

-- Route Students (many-to-many relationship)
CREATE TABLE route_students (
    route_id UUID NOT NULL,
    student_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (route_id, student_id),
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

CREATE INDEX idx_route_students_student_id ON route_students(student_id);

-- Route Driver Assignment
CREATE TABLE route_driver_assignment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL,
    driver_user_id UUID NOT NULL,
    active_from TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active_to TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_route_driver_assignment_route_id ON route_driver_assignment(route_id);
CREATE INDEX idx_route_driver_assignment_driver_user_id ON route_driver_assignment(driver_user_id);
CREATE INDEX idx_route_driver_assignment_active ON route_driver_assignment(active_from, active_to);

-- Trips table
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    route_id UUID NOT NULL,
    driver_id UUID NOT NULL,
    trip_type trip_type_enum NOT NULL,
    status trip_status_enum NOT NULL,
    start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_trips_tenant_id ON trips(tenant_id);
CREATE INDEX idx_trips_route_id ON trips(route_id);
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_start_time ON trips(start_time);

-- Attendance table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL,
    student_id UUID NOT NULL,
    status attendance_status_enum,
    marked_by UUID,
    marked_at TIMESTAMP,
    locked BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT,
    FOREIGN KEY (marked_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_attendance_trip_id ON attendance(trip_id);
CREATE INDEX idx_attendance_student_id ON attendance(student_id);
CREATE INDEX idx_attendance_status ON attendance(status);

-- Attendance Audit table
CREATE TABLE attendance_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_id UUID NOT NULL,
    edited_by UUID NOT NULL,
    old_status attendance_status_enum,
    new_status attendance_status_enum,
    reason VARCHAR(500),
    edited_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (attendance_id) REFERENCES attendance(id) ON DELETE CASCADE,
    FOREIGN KEY (edited_by) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_attendance_audit_attendance_id ON attendance_audit(attendance_id);
CREATE INDEX idx_attendance_audit_edited_at ON attendance_audit(edited_at);

-- Latest Bus Location table
CREATE TABLE latest_bus_location (
    trip_id UUID PRIMARY KEY,
    route_id UUID NOT NULL,
    driver_id UUID NOT NULL,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    accuracy_m DECIMAL(10, 2),
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE RESTRICT,
    FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_latest_bus_location_route_id ON latest_bus_location(route_id);
CREATE INDEX idx_latest_bus_location_updated_at ON latest_bus_location(updated_at);

-- GPS Logs table
CREATE TABLE gps_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    accuracy_m DECIMAL(10, 2),
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);

CREATE INDEX idx_gps_logs_trip_id ON gps_logs(trip_id);
CREATE INDEX idx_gps_logs_timestamp ON gps_logs(timestamp);

-- Notification Log table
CREATE TABLE notification_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL,
    type notification_type_enum NOT NULL,
    status notification_status_enum NOT NULL,
    provider_message_id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);

CREATE INDEX idx_notification_log_trip_id ON notification_log(trip_id);
CREATE INDEX idx_notification_log_status ON notification_log(status);
CREATE INDEX idx_notification_log_created_at ON notification_log(created_at);

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE users IS 'Stores all system users including drivers, parents, and admins';
COMMENT ON TABLE students IS 'Student records linked to parent users';
COMMENT ON TABLE routes IS 'Bus routes configured in the system';
COMMENT ON TABLE route_students IS 'Many-to-many relationship between routes and students';
COMMENT ON TABLE route_driver_assignment IS 'Tracks driver assignments to routes over time';
COMMENT ON TABLE trips IS 'Individual trip instances for pickup or drop operations';
COMMENT ON TABLE attendance IS 'Student attendance records for each trip';
COMMENT ON TABLE attendance_audit IS 'Audit trail for attendance modifications';
COMMENT ON TABLE latest_bus_location IS 'Current location of active buses';
COMMENT ON TABLE gps_logs IS 'Historical GPS tracking data';
COMMENT ON TABLE notification_log IS 'Log of all notifications sent to parents';

-- ============================================================================
-- CRITICAL CONSTRAINTS
-- ============================================================================

-- 1. Idempotency Constraint: Prevent duplicate notifications for same trip and type
ALTER TABLE notification_log 
ADD CONSTRAINT uq_notification_log_trip_type UNIQUE (trip_id, type);

-- 2. Active Trip Guard: Ensure only one active trip per route and type
CREATE UNIQUE INDEX idx_trips_active_route_type 
ON trips(route_id, trip_type) 
WHERE status = 'ACTIVE';

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Additional indexes for route_driver_assignment
CREATE INDEX idx_route_driver_assignment_driver_id ON route_driver_assignment(driver_id);

-- Additional indexes for trips (tenant_id, route_id, driver_id already created above)
-- These were already included in the initial schema, so they're documented here for reference

-- Additional indexes for attendance (trip_id already created above)
-- Already included in the initial schema

-- Additional indexes for latest_bus_location (updated_at already created above)
-- Already included in the initial schema

-- Additional indexes for gps_logs
CREATE INDEX idx_gps_logs_received_at ON gps_logs(received_at);

-- ============================================================================
-- ADDITIONAL USEFUL CONSTRAINTS
-- ============================================================================

-- Ensure trip end_time is after start_time
ALTER TABLE trips 
ADD CONSTRAINT chk_trips_end_after_start 
CHECK (end_time IS NULL OR end_time >= start_time);

-- Ensure route_driver_assignment active_to is after active_from
ALTER TABLE route_driver_assignment 
ADD CONSTRAINT chk_assignment_valid_period 
CHECK (active_to IS NULL OR active_to >= active_from);

-- Ensure attendance can only be marked once per student per trip
ALTER TABLE attendance 
ADD CONSTRAINT uq_attendance_trip_student UNIQUE (trip_id, student_id);

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
