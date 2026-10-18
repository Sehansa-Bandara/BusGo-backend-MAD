-- BusGo PostgreSQL Schema

-- Enable UUID extension if required
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create Enum Types
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('passenger', 'driver', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE bus_category AS ENUM ('Luxury', 'Semi-Luxury', 'Express', 'Normal', 'A/C');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE seat_state AS ENUM ('AVAILABLE', 'HELD', 'BOOKED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE booking_status AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE ticket_status AS ENUM ('VALID', 'USED', 'CANCELLED', 'EXPIRED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE alert_type AS ENUM ('DELAY', 'EMERGENCY', 'SCHEDULE_CHANGE', 'GENERAL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE incident_status AS ENUM ('REPORTED', 'INVESTIGATING', 'RESOLVED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create Tables

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'passenger',
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Buses Table
CREATE TABLE IF NOT EXISTS buses (
    id SERIAL PRIMARY KEY,
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    operator_name VARCHAR(100) NOT NULL,
    route_number VARCHAR(20) NOT NULL,
    category bus_category NOT NULL DEFAULT 'Normal',
    origin VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    duration VARCHAR(50),
    seat_capacity INT NOT NULL DEFAULT 40,
    fare DECIMAL(10, 2) NOT NULL,
    progress FLOAT DEFAULT 0.0,
    amenities TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Stops Table
CREATE TABLE IF NOT EXISTS stops (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20),
    route_id VARCHAR(20) NOT NULL,
    distance_from_origin DECIMAL(8, 2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_stop_route UNIQUE (name, route_id)
);

-- Bus Seats Table
CREATE TABLE IF NOT EXISTS bus_seats (
    id SERIAL PRIMARY KEY,
    bus_id INT NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    seat_number VARCHAR(10) NOT NULL,
    state seat_state NOT NULL DEFAULT 'AVAILABLE',
    held_by_user_id INT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_bus_seat UNIQUE (bus_id, seat_number)
);

-- Bookings Table
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bus_id INT NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    boarding_stop_id INT REFERENCES stops(id) ON DELETE SET NULL,
    alighting_stop_id INT REFERENCES stops(id) ON DELETE SET NULL,
    travel_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status booking_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Booking Seats Junction Table
CREATE TABLE IF NOT EXISTS booking_seats (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    seat_number VARCHAR(10) NOT NULL,
    CONSTRAINT unique_booking_seat UNIQUE (booking_id, seat_number)
);

-- Tickets Table
CREATE TABLE IF NOT EXISTS tickets (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    status ticket_status NOT NULL DEFAULT 'VALID',
    issued_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMPTZ
);

-- Payments Table (Stripe Payment Integration)
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    stripe_payment_intent_id VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'lkr',
    status payment_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Alerts Table
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    type alert_type NOT NULL DEFAULT 'GENERAL',
    title VARCHAR(200) NOT NULL,
    description TEXT,
    time_ago VARCHAR(50),
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Incidents Table
CREATE TABLE IF NOT EXISTS incidents (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    driver_id INT REFERENCES users(id) ON DELETE SET NULL,
    incident_type VARCHAR(50) NOT NULL,
    description TEXT,
    status incident_status NOT NULL DEFAULT 'REPORTED',
    reported_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ
);

-- Driver Location Tracking Table (for DriverScreen & LiveTrackingScreen)
CREATE TABLE IF NOT EXISTS driver_locations (
    id SERIAL PRIMARY KEY,
    bus_id INT NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    driver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5, 2) DEFAULT 0.0,
    heading DECIMAL(5, 2) DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_driver_location UNIQUE (bus_id, driver_id)
);

-- Device Tokens Table (FCM Tokens for Push Notifications)
CREATE TABLE IF NOT EXISTS device_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Places Table (matching user schema: "busId", "driverId", "from", "to")
CREATE TABLE IF NOT EXISTS places (
    id SERIAL PRIMARY KEY,
    "busId" INT REFERENCES buses(id) ON DELETE CASCADE,
    "driverId" INT REFERENCES users(id) ON DELETE SET NULL,
    "from" VARCHAR(100) NOT NULL,
    "to" VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create Indexes

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_buses_route_number ON buses(route_number);
CREATE INDEX IF NOT EXISTS idx_buses_origin ON buses(origin);
CREATE INDEX IF NOT EXISTS idx_buses_destination ON buses(destination);
CREATE INDEX IF NOT EXISTS idx_bus_seats_bus_id ON bus_seats(bus_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_bus_id ON bookings(bus_id);
CREATE INDEX IF NOT EXISTS idx_bookings_travel_date ON bookings(travel_date);
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_intent_id ON payments(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_alerts_bus_id ON alerts(bus_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_bus_id ON driver_locations(bus_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_places_bus_id ON places("busId");


