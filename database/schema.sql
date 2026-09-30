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
CREATE INDEX IF NOT EXISTS idx_alerts_bus_id ON alerts(bus_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_bus_id ON driver_locations(bus_id);

-- 4. Seed Data (Development & Testing)

-- Sample Users
INSERT INTO users (name, email, phone, password_hash, role, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship)
VALUES
    ('John Passenger', 'john.passenger@example.com', '+94771234567', '$2a$10$e.SampleHashedPasswordForJohn123', 'passenger', 'Mary Doe', '+94779876543', 'Spouse'),
    ('Sunil Perera', 'sunil.driver@example.com', '+94712345678', '$2a$10$e.SampleHashedPasswordForSunil123', 'driver', 'Kanthi Perera', '+94718765432', 'Wife'),
    ('Admin User', 'admin@busgo.lk', '+94112345678', '$2a$10$e.SampleHashedPasswordForAdmin123', 'admin', 'System Admin', '+94118765432', 'Colleague')
ON CONFLICT (email) DO NOTHING;

-- Sample Route 06 Stops (Kurunegala -> Colombo Fort)
INSERT INTO stops (name, code, route_id, distance_from_origin)
VALUES
    ('Kurunegala', 'KRN', '06', 0.0),
    ('Polgahawela', 'PLG', '06', 15.2),
    ('Alawwa', 'ALW', '06', 28.5),
    ('Warakapola', 'WKP', '06', 42.0),
    ('Nittambuwa', 'NTB', '06', 60.5),
    ('Kadawatha', 'KDW', '06', 81.0),
    ('Colombo Fort', 'CMB', '06', 94.0)
ON CONFLICT (name, route_id) DO NOTHING;

-- Sample Buses (Route 06)
INSERT INTO buses (plate_number, operator_name, route_number, category, origin, destination, departure_time, arrival_time, duration, seat_capacity, fare, progress, amenities)
VALUES
    ('NC-4589', 'Wayamba Express', '06', 'Luxury', 'Kurunegala', 'Colombo Fort', '06:00:00', '08:30:00', '2h 30m', 40, 850.00, 0.45, ARRAY['A/C', 'USB Charging', 'Reclining Seats']),
    ('ND-1234', 'Rajarata Transport', '06', 'A/C', 'Kurunegala', 'Colombo Fort', '07:15:00', '09:45:00', '2h 30m', 40, 750.00, 0.10, ARRAY['A/C', 'Adjustable Seats']),
    ('ND-5678', 'Super Line', '06', 'Express', 'Colombo Fort', 'Kurunegala', '08:00:00', '10:30:00', '2h 30m', 40, 650.00, 0.00, ARRAY['Curtains', 'Luggage Storage'])
ON CONFLICT (plate_number) DO NOTHING;

-- Auto-generate 40 Seats per Bus
INSERT INTO bus_seats (bus_id, seat_number, state)
SELECT b.id, s.seat_num::text, 'AVAILABLE'::seat_state
FROM buses b
CROSS JOIN generate_series(1, 40) AS s(seat_num)
ON CONFLICT (bus_id, seat_number) DO NOTHING;

-- Sample Alerts
INSERT INTO alerts (type, title, description, time_ago, bus_id)
SELECT 'DELAY'::alert_type, 'Traffic Delay on Kandy Road', 'Bus NC-4589 is experiencing a 15-minute delay near Warakapola due to heavy traffic.', '10 mins ago', id
FROM buses WHERE plate_number = 'NC-4589';

-- Sample Driver Location
INSERT INTO driver_locations (bus_id, driver_id, latitude, longitude, speed, heading)
SELECT b.id, u.id, 7.2285, 80.2039, 55.4, 180.0
FROM buses b, users u
WHERE b.plate_number = 'NC-4589' AND u.email = 'sunil.driver@example.com'
ON CONFLICT (bus_id, driver_id) DO NOTHING;
