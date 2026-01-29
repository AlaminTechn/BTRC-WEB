-- BTRC QoS Monitoring System - Database Schema
-- Version: 1.0
-- Database: PostgreSQL 15 + TimescaleDB

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- =====================================================
-- STEP 1: FOUNDATION TABLES
-- =====================================================

-- Geographic Divisions (8 divisions in Bangladesh)
CREATE TABLE IF NOT EXISTS geo_divisions (
    id SERIAL PRIMARY KEY,
    bbs_code CHAR(2) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_bn VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Geographic Districts (64 districts)
CREATE TABLE IF NOT EXISTS geo_districts (
    id SERIAL PRIMARY KEY,
    division_id INTEGER REFERENCES geo_divisions(id),
    bbs_code CHAR(4) UNIQUE NOT NULL,
    district_code CHAR(2) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_bn VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Geographic Upazilas (495 upazilas)
CREATE TABLE IF NOT EXISTS geo_upazilas (
    id SERIAL PRIMARY KEY,
    district_id INTEGER REFERENCES geo_districts(id),
    bbs_code CHAR(6) UNIQUE NOT NULL,
    upazila_code CHAR(2) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_bn VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- ISP License Categories
CREATE TABLE IF NOT EXISTS isp_license_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    name_bn VARCHAR(100),
    description TEXT,
    coverage_scope VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- =====================================================
-- STEP 2: INFRASTRUCTURE TABLES
-- =====================================================

-- PoP Categories
CREATE TABLE IF NOT EXISTS pop_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Upstream Types
CREATE TABLE IF NOT EXISTS upstream_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ISPs Master Table
CREATE TABLE IF NOT EXISTS isps (
    id SERIAL PRIMARY KEY,
    btrc_license_no VARCHAR(50) UNIQUE NOT NULL,
    name_en VARCHAR(200) NOT NULL,
    name_bn VARCHAR(200),
    trade_name VARCHAR(200),
    license_category_id INTEGER REFERENCES isp_license_categories(id),
    license_issue_date DATE,
    license_expiry_date DATE,
    license_status VARCHAR(20) DEFAULT 'ACTIVE',
    headquarters_district_id INTEGER REFERENCES geo_districts(id),
    address TEXT,
    website VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    total_subscribers INTEGER DEFAULT 0,
    total_bandwidth_gbps DECIMAL(10,2),
    api_enabled BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- PoPs (Points of Presence)
CREATE TABLE IF NOT EXISTS pops (
    id SERIAL PRIMARY KEY,
    isp_id INTEGER REFERENCES isps(id) NOT NULL,
    code VARCHAR(50),
    name_en VARCHAR(200) NOT NULL,
    category_id INTEGER REFERENCES pop_categories(id),
    district_id INTEGER REFERENCES geo_districts(id),
    address TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    upstream_type_id INTEGER REFERENCES upstream_types(id),
    upstream_bandwidth_mbps INTEGER,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Software Agents
CREATE TABLE IF NOT EXISTS software_agents (
    id SERIAL PRIMARY KEY,
    isp_id INTEGER REFERENCES isps(id) NOT NULL,
    agent_type VARCHAR(20) NOT NULL,
    agent_uuid VARCHAR(50),
    name VARCHAR(200),
    description TEXT,
    version VARCHAR(20),
    host_ip VARCHAR(45),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- =====================================================
-- STEP 3: PRODUCT & SUBSCRIBER TABLES
-- =====================================================

-- Package Types
CREATE TABLE IF NOT EXISTS package_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Connection Types
CREATE TABLE IF NOT EXISTS connection_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Packages
CREATE TABLE IF NOT EXISTS packages (
    id SERIAL PRIMARY KEY,
    isp_id INTEGER REFERENCES isps(id) NOT NULL,
    package_type_id INTEGER REFERENCES package_types(id),
    connection_type_id INTEGER REFERENCES connection_types(id),
    code VARCHAR(50),
    name_en VARCHAR(200) NOT NULL,
    download_speed_mbps DECIMAL(10,2),
    upload_speed_mbps DECIMAL(10,2),
    monthly_price_bdt DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Agent-PoP Assignments
CREATE TABLE IF NOT EXISTS agent_pop_assignments (
    id SERIAL PRIMARY KEY,
    agent_id INTEGER REFERENCES software_agents(id) NOT NULL,
    pop_id INTEGER REFERENCES pops(id) NOT NULL,
    assignment_date DATE DEFAULT CURRENT_DATE,
    is_primary BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(agent_id, pop_id)
);

-- Subscriber Snapshots
CREATE TABLE IF NOT EXISTS subscriber_snapshots (
    id SERIAL PRIMARY KEY,
    isp_id INTEGER REFERENCES isps(id) NOT NULL,
    snapshot_month DATE NOT NULL,
    package_id INTEGER REFERENCES packages(id),
    district_id INTEGER REFERENCES geo_districts(id),
    total_subscribers INTEGER DEFAULT 0,
    active_subscribers INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 4: QOS & COMPLIANCE TABLES
-- =====================================================

-- QoS Parameters
CREATE TABLE IF NOT EXISTS qos_parameters (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    unit VARCHAR(20),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- QoS Test Targets
CREATE TABLE IF NOT EXISTS qos_test_targets (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50),
    name_en VARCHAR(200) NOT NULL,
    target_type VARCHAR(20),
    host VARCHAR(255),
    port INTEGER,
    is_bdix BOOLEAN DEFAULT false,
    expected_latency_ms DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SLA Thresholds
CREATE TABLE IF NOT EXISTS sla_thresholds (
    id SERIAL PRIMARY KEY,
    qos_parameter_id INTEGER REFERENCES qos_parameters(id) NOT NULL,
    license_category_id INTEGER REFERENCES isp_license_categories(id),
    package_type_id INTEGER REFERENCES package_types(id),
    threshold_type VARCHAR(20),
    threshold_value DECIMAL(15,4),
    warning_threshold DECIMAL(15,4),
    effective_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- STEP 5: TIME-SERIES TABLES (Hypertables)
-- =====================================================

-- Interface Metrics (from SNMP agents)
CREATE TABLE IF NOT EXISTS ts_interface_metrics (
    time TIMESTAMPTZ NOT NULL,
    pop_id INTEGER NOT NULL,
    upstream_type_id INTEGER,
    agent_id INTEGER,
    in_bps BIGINT,
    out_bps BIGINT,
    in_errors BIGINT DEFAULT 0,
    out_errors BIGINT DEFAULT 0,
    in_discards BIGINT DEFAULT 0,
    out_discards BIGINT DEFAULT 0,
    utilization_in_pct DECIMAL(5,2),
    utilization_out_pct DECIMAL(5,2)
);

-- Convert to hypertable
SELECT create_hypertable('ts_interface_metrics', 'time', if_not_exists => TRUE);

-- Subscriber Counts (time-series)
CREATE TABLE IF NOT EXISTS ts_subscriber_counts (
    time TIMESTAMPTZ NOT NULL,
    pop_id INTEGER NOT NULL,
    agent_id INTEGER,
    active_sessions INTEGER DEFAULT 0,
    pppoe_sessions INTEGER DEFAULT 0,
    dhcp_leases INTEGER DEFAULT 0
);

SELECT create_hypertable('ts_subscriber_counts', 'time', if_not_exists => TRUE);

-- QoS Measurements (speed tests, latency, etc.)
CREATE TABLE IF NOT EXISTS ts_qos_measurements (
    time TIMESTAMPTZ NOT NULL,
    pop_id INTEGER NOT NULL,
    agent_id INTEGER,
    test_target_id INTEGER,
    test_type VARCHAR(30),
    is_bdix BOOLEAN DEFAULT false,
    latency_ms DECIMAL(10,2),
    jitter_ms DECIMAL(10,2),
    packet_loss_pct DECIMAL(5,2),
    download_mbps DECIMAL(10,2),
    upload_mbps DECIMAL(10,2)
);

SELECT create_hypertable('ts_qos_measurements', 'time', if_not_exists => TRUE);

-- SLA Violations
CREATE TABLE IF NOT EXISTS sla_violations (
    id SERIAL PRIMARY KEY,
    isp_id INTEGER NOT NULL,
    pop_id INTEGER,
    qos_parameter_id INTEGER NOT NULL,
    sla_threshold_id INTEGER,
    violation_type VARCHAR(30),
    severity VARCHAR(20) DEFAULT 'WARNING',
    detection_time TIMESTAMPTZ NOT NULL,
    expected_value DECIMAL(15,4),
    actual_value DECIMAL(15,4),
    deviation_pct DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'OPEN',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_geo_districts_division ON geo_districts(division_id);
CREATE INDEX IF NOT EXISTS idx_geo_upazilas_district ON geo_upazilas(district_id);
CREATE INDEX IF NOT EXISTS idx_isps_license_category ON isps(license_category_id);
CREATE INDEX IF NOT EXISTS idx_isps_district ON isps(headquarters_district_id);
CREATE INDEX IF NOT EXISTS idx_pops_isp ON pops(isp_id);
CREATE INDEX IF NOT EXISTS idx_pops_district ON pops(district_id);
CREATE INDEX IF NOT EXISTS idx_pops_category ON pops(category_id);
CREATE INDEX IF NOT EXISTS idx_agents_isp ON software_agents(isp_id);
CREATE INDEX IF NOT EXISTS idx_agents_pop ON software_agents(pop_id);
CREATE INDEX IF NOT EXISTS idx_packages_isp ON packages(isp_id);
CREATE INDEX IF NOT EXISTS idx_subscriber_snapshots_isp ON subscriber_snapshots(isp_id);
CREATE INDEX IF NOT EXISTS idx_subscriber_snapshots_date ON subscriber_snapshots(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_violations_isp ON sla_violations(isp_id);
CREATE INDEX IF NOT EXISTS idx_violations_time ON sla_violations(violation_time);

-- Time-series indexes
CREATE INDEX IF NOT EXISTS idx_ts_interface_pop_time ON ts_interface_metrics(pop_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_ts_subscriber_isp_time ON ts_subscriber_counts(isp_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_ts_qos_pop_time ON ts_qos_measurements(pop_id, time DESC);

-- =====================================================
-- DONE
-- =====================================================
