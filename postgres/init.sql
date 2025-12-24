-- Database is already created by POSTGRES_DB environment variable
-- This script runs in the context of the trafficdb database

-- Create metadata_index table for traffic-control
CREATE TABLE IF NOT EXISTS metadata_index (
    id SERIAL PRIMARY KEY,
    traffic_light_id VARCHAR(255) NOT NULL,
    timestamp BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_metadata_index UNIQUE (type, timestamp, traffic_light_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_metadata_traffic_light ON metadata_index(traffic_light_id);
CREATE INDEX IF NOT EXISTS idx_metadata_timestamp ON metadata_index(timestamp);
CREATE INDEX IF NOT EXISTS idx_metadata_type ON metadata_index(type);

