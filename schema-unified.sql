-- Unified Schema for TOS (Transport Operations System)
-- Combines Driver App + Web App schemas
-- Created: 2026-03-09

-- ============================================================================
-- PART 1: USER MANAGEMENT (from web-app-schema-1.sql)
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types for users
CREATE TYPE user_role_enum AS ENUM ('ADMIN', 'PARENT', 'DRIVER');
CREATE TYPE user_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED');

-- Tenants table (Schools/Organizations)
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_status ON tenants(status);

-- Users table (Admin, Parent, Driver)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role user_role_enum NOT NULL,
    status user_status_enum NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_phone ON users(phone);

-- Drivers table (extends users with driver-specific info)
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    license_number VARCHAR(50) NOT NULL,
    license_expiry DATE NOT NULL,
    vehicle_number VARCHAR(50),
    vehicle_type VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_drivers_tenant ON drivers(tenant_id);
CREATE INDEX idx_drivers_user ON drivers(user_id);
CREATE INDEX idx_drivers_status ON drivers(status);

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    grade VARCHAR(50),
    section VARCHAR(50),
    roll_number VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    blood_group VARCHAR(5),
    address TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'GRADUATED')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_students_tenant ON students(tenant_id);
CREATE INDEX idx_students_status ON students(status);
CREATE INDEX idx_students_grade ON students(grade);

-- Student Parents junction table (a student can have multiple parents)
CREATE TABLE student_parents (
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    parent_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship VARCHAR(50) NOT NULL CHECK (relationship IN ('FATHER', 'MOTHER', 'GUARDIAN', 'OTHER')),
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (student_id, parent_user_id)
);

CREATE INDEX idx_student_parents_student ON student_parents(student_id);
CREATE INDEX idx_student_parents_parent ON student_parents(parent_user_id);

-- ============================================================================
-- PART 2: TRANSPORT OPERATIONS (from web-app-schema-2.sql)
-- ============================================================================

-- Create ENUM types for transport operations
CREATE TYPE trip_type_enum AS ENUM ('PICKUP', 'DROP');
CREATE TYPE trip_status_enum AS ENUM ('ACTIVE', 'ENDED');
CREATE TYPE attendance_status_enum AS ENUM ('PRESENT', 'ABSENT');
CREATE TYPE notification_type_enum AS ENUM ('TRIP_START');
CREATE TYPE notification_status_enum AS ENUM ('QUEUED', 'SENT', 'FAILED');

-- Routes table
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_routes_tenant ON routes(tenant_id);
CREATE INDEX idx_routes_status ON routes(status);

-- Route Students junction table
CREATE TABLE route_students (
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (route_id, student_id)
);

CREATE INDEX idx_route_students_student ON route_students(student_id);

-- Route Driver Assignment table
CREATE TABLE route_driver_assignment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    active_from TIMESTAMP NOT NULL DEFAULT NOW(),
    active_to TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_route_driver_route ON route_driver_assignment(route_id);
CREATE INDEX idx_route_driver_driver ON route_driver_assignment(driver_id);
CREATE INDEX idx_route_driver_active ON route_driver_assignment(route_id, active_to) WHERE active_to IS NULL;

-- Constraint: Only one active driver per route
CREATE UNIQUE INDEX idx_one_active_driver_per_route 
    ON route_driver_assignment(route_id) 
    WHERE active_to IS NULL;

-- Trips table
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    trip_type trip_type_enum NOT NULL,
    trip_date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NULL,
    status trip_status_enum NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_tenant ON trips(tenant_id);
CREATE INDEX idx_trips_route ON trips(route_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_date ON trips(trip_date);
CREATE INDEX idx_trips_status ON trips(status);

-- Constraint: Only one active trip per route per trip type
CREATE UNIQUE INDEX idx_one_active_trip_per_route_type 
    ON trips(route_id, trip_type) 
    WHERE status = 'ACTIVE';

-- Constraint: Ensure trip end_time is after start_time
ALTER TABLE trips 
ADD CONSTRAINT chk_trips_end_after_start 
CHECK (end_time IS NULL OR end_time >= start_time);

-- Attendance table
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
    status attendance_status_enum NULL,
    marked_at TIMESTAMP NULL,
    marked_by UUID NULL REFERENCES users(id) ON DELETE SET NULL,
    locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attendance_trip ON attendance(trip_id);
CREATE INDEX idx_attendance_student ON attendance(student_id);
CREATE INDEX idx_attendance_status ON attendance(status);
CREATE UNIQUE INDEX idx_attendance_trip_student ON attendance(trip_id, student_id);

-- Attendance Audit table
CREATE TABLE attendance_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_id UUID NOT NULL REFERENCES attendance(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
    old_status attendance_status_enum,
    new_status attendance_status_enum,
    reason TEXT,
    edited_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    edited_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attendance_audit_attendance ON attendance_audit(attendance_id);
CREATE INDEX idx_attendance_audit_trip ON attendance_audit(trip_id);
CREATE INDEX idx_attendance_audit_student ON attendance_audit(student_id);
CREATE INDEX idx_attendance_audit_edited_by ON attendance_audit(edited_by);

-- Latest Bus Location table (single row per trip)
CREATE TABLE latest_bus_location (
    trip_id UUID PRIMARY KEY REFERENCES trips(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE RESTRICT,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5, 2) NULL,
    heading DECIMAL(5, 2) NULL,
    accuracy_m DECIMAL(10, 2) NULL,
    timestamp TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_latest_bus_location_route ON latest_bus_location(route_id);
CREATE INDEX idx_latest_bus_location_timestamp ON latest_bus_location(timestamp);
CREATE INDEX idx_latest_bus_location_updated_at ON latest_bus_location(updated_at);

-- GPS Logs table (historical tracking)
CREATE TABLE gps_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5, 2) NULL,
    heading DECIMAL(5, 2) NULL,
    accuracy_m DECIMAL(10, 2) NULL,
    timestamp TIMESTAMP NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_gps_logs_trip ON gps_logs(trip_id);
CREATE INDEX idx_gps_logs_timestamp ON gps_logs(timestamp);
CREATE INDEX idx_gps_logs_received_at ON gps_logs(received_at);
CREATE INDEX idx_gps_logs_trip_timestamp ON gps_logs(trip_id, timestamp DESC);

-- Notification Log table
CREATE TABLE notification_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    type notification_type_enum NOT NULL,
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status notification_status_enum NOT NULL DEFAULT 'QUEUED',
    provider_message_id VARCHAR(255),
    sent_at TIMESTAMP NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_log_trip ON notification_log(trip_id);
CREATE INDEX idx_notification_log_recipient ON notification_log(recipient_user_id);
CREATE INDEX idx_notification_log_status ON notification_log(status);
CREATE INDEX idx_notification_log_created_at ON notification_log(created_at);

-- Constraint: WhatsApp batch idempotency - one notification per trip per type
CREATE UNIQUE INDEX idx_notification_log_trip_type ON notification_log(trip_id, type);

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE tenants IS 'Schools or organizations using the system';
COMMENT ON TABLE users IS 'System users (admins, parents, drivers)';
COMMENT ON TABLE drivers IS 'Driver-specific information';
COMMENT ON TABLE students IS 'Student information';
COMMENT ON TABLE student_parents IS 'Maps students to their parent users';
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
-- END OF UNIFIED SCHEMA
-- ============================================================================
