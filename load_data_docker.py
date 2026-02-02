#!/usr/bin/env python3
"""
BTRC QoS Monitoring - Data Loader (Docker Version)
Loads JSON data files into PostgreSQL/TimescaleDB

Usage inside Docker: python load_data_docker.py
"""

import json
import os
import psycopg2
from psycopg2.extras import execute_values
from pathlib import Path
from datetime import datetime

# Database configuration - uses Docker network hostname
DB_CONFIG = {
    'dbname': os.getenv('POSTGRES_DB', 'btrc_qos'),
    'user': os.getenv('POSTGRES_USER', 'btrc'),
    'password': os.getenv('POSTGRES_PASSWORD', 'btrc_password'),
    'host': os.getenv('POSTGRES_HOST', 'btrc-db'),  # Docker service name
    'port': int(os.getenv('POSTGRES_PORT', '5432'))  # Internal port
}

# Data directory
DATA_DIR = Path(__file__).parent / 'dummy_data_v' / 'dummy_data'

# File to table mapping with column specifications
FILE_TABLE_MAP = {
    # Tier P: Prerequisites (Geographic & License)
    'P.01_geo_divisions': {
        'table': 'geo_divisions',
        'columns': ['id', 'bbs_code', 'name_en', 'name_bn', 'latitude', 'longitude', 'is_active']
    },
    'P.02_geo_districts': {
        'table': 'geo_districts',
        'columns': ['id', 'division_id', 'bbs_code', 'district_code', 'name_en', 'name_bn', 'latitude', 'longitude', 'is_active']
    },
    'P.04_isp_license_categories': {
        'table': 'isp_license_categories',
        'columns': ['id', 'code', 'name_en', 'name_bn', 'description', 'coverage_scope', 'is_active']
    },
    # Tier A: Lookups
    'A.01_pop_categories': {
        'table': 'pop_categories',
        'columns': ['id', 'code', 'name_en', 'description', 'is_active']
    },
    'A.02_upstream_types': {
        'table': 'upstream_types',
        'columns': ['id', 'code', 'name_en', 'description', 'is_active']
    },
    'A.03_package_types': {
        'table': 'package_types',
        'columns': ['id', 'code', 'name_en', 'description', 'is_active']
    },
    'A.04_connection_types': {
        'table': 'connection_types',
        'columns': ['id', 'code', 'name_en', 'description', 'is_active']
    },
    'A.05_qos_parameters': {
        'table': 'qos_parameters',
        'columns': ['id', 'code', 'name_en', 'unit', 'description', 'is_active']
    },
    # Tier B: Master Data
    'B.01_isps': {
        'table': 'isps',
        'columns': ['id', 'btrc_license_no', 'name_en', 'name_bn', 'trade_name',
                   'license_category_id', 'license_issue_date', 'license_expiry_date',
                   'license_status', 'headquarters_district_id', 'address', 'website',
                   'email', 'phone', 'total_subscribers', 'total_bandwidth_gbps',
                   'api_enabled', 'is_active']
    },
    'B.02_pops': {
        'table': 'pops',
        'columns': ['id', 'isp_id', 'code', 'name_en', 'category_id',
                   'district_id', 'address', 'latitude', 'longitude',
                   'upstream_type_id', 'upstream_bandwidth_mbps', 'status', 'is_active']
    },
    'B.03_agents': {
        'table': 'software_agents',
        'columns': ['id', 'isp_id', 'agent_type', 'agent_uuid', 'name',
                   'description', 'version', 'host_ip', 'status', 'is_active']
    },
    'B.04_packages': {
        'table': 'packages',
        'columns': ['id', 'isp_id', 'package_type_id', 'connection_type_id',
                   'code', 'name_en', 'download_speed_mbps', 'upload_speed_mbps',
                   'monthly_price_bdt', 'is_active']
    },
    'B.05_qos_test_targets': {
        'table': 'qos_test_targets',
        'columns': ['id', 'code', 'name_en', 'target_type', 'host',
                   'port', 'is_bdix', 'expected_latency_ms', 'is_active']
    },
    'B.06_sla_thresholds': {
        'table': 'sla_thresholds',
        'columns': ['id', 'qos_parameter_id', 'license_category_id', 'package_type_id',
                   'threshold_type', 'threshold_value', 'warning_threshold',
                   'effective_date', 'is_active']
    },
    # Tier C: Relationships
    'C.01_agent_pop_assignments': {
        'table': 'agent_pop_assignments',
        'columns': ['id', 'agent_id', 'pop_id', 'assignment_date', 'is_primary', 'is_active']
    },
    'C.02_subscriber_snapshots': {
        'table': 'subscriber_snapshots',
        'columns': ['id', 'isp_id', 'snapshot_month', 'package_id', 'district_id',
                   'total_subscribers', 'active_subscribers']
    },
    # Tier D: Time-Series (large files)
    'D.01_ts_interface_metrics': {
        'table': 'ts_interface_metrics',
        'columns': ['time', 'pop_id', 'upstream_type_id', 'agent_id',
                   'in_bps', 'out_bps', 'in_errors', 'out_errors',
                   'in_discards', 'out_discards', 'utilization_in_pct', 'utilization_out_pct'],
        'batch_size': 10000
    },
    'D.02_ts_subscriber_counts': {
        'table': 'ts_subscriber_counts',
        'columns': ['time', 'pop_id', 'agent_id', 'active_sessions',
                   'pppoe_sessions', 'dhcp_leases'],
        'batch_size': 10000
    },
    'D.03_ts_qos_measurements': {
        'table': 'ts_qos_measurements',
        'columns': ['time', 'pop_id', 'agent_id', 'test_target_id', 'test_type',
                   'is_bdix', 'latency_ms', 'jitter_ms', 'packet_loss_pct',
                   'download_mbps', 'upload_mbps'],
        'batch_size': 10000
    },
    # Tier E: Compliance
    'E.01_violations': {
        'table': 'sla_violations',
        'columns': ['id', 'isp_id', 'pop_id', 'qos_parameter_id', 'sla_threshold_id',
                   'violation_type', 'severity', 'detection_time',
                   'expected_value', 'actual_value', 'deviation_pct', 'status']
    }
}

def load_json_file(filepath):
    """Load JSON file and return data"""
    print(f"  Reading {filepath.name}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def extract_values(record, columns):
    """Extract values from record based on column list"""
    values = []
    for col in columns:
        val = record.get(col)
        if val is None:
            values.append(None)
        elif isinstance(val, bool):
            values.append(val)
        else:
            values.append(val)
    return tuple(values)

def load_table(conn, config, data, prefix):
    """Load data into a table"""
    table = config['table']
    columns = config['columns']
    batch_size = config.get('batch_size', 1000)

    print(f"  Loading {len(data)} records into {table}...")

    cols_str = ', '.join(columns)
    placeholders = ', '.join(['%s'] * len(columns))

    if 'id' in columns:
        sql = f"""
            INSERT INTO {table} ({cols_str})
            VALUES ({placeholders})
            ON CONFLICT (id) DO NOTHING
        """
    else:
        sql = f"INSERT INTO {table} ({cols_str}) VALUES ({placeholders})"

    cursor = conn.cursor()

    try:
        for i in range(0, len(data), batch_size):
            batch = data[i:i+batch_size]
            values_list = [extract_values(record, columns) for record in batch]

            for values in values_list:
                try:
                    cursor.execute(sql, values)
                except Exception as e:
                    print(f"    Warning: Error inserting record: {e}")
                    continue

            conn.commit()
            if len(data) > batch_size:
                print(f"    Processed {min(i+batch_size, len(data))}/{len(data)} records...")

        print(f"  ✓ Loaded {table}")
        return True

    except Exception as e:
        print(f"  ✗ Error loading {table}: {e}")
        conn.rollback()
        return False
    finally:
        cursor.close()

def reset_sequences(conn):
    """Reset all sequences to max(id) + 1"""
    cursor = conn.cursor()

    tables_with_id = [
        'pop_categories', 'upstream_types', 'package_types', 'connection_types',
        'qos_parameters', 'isps', 'pops', 'software_agents', 'packages',
        'qos_test_targets', 'sla_thresholds', 'agent_pop_assignments',
        'subscriber_snapshots', 'sla_violations'
    ]

    for table in tables_with_id:
        try:
            cursor.execute(f"""
                SELECT setval(pg_get_serial_sequence('{table}', 'id'),
                       COALESCE((SELECT MAX(id) FROM {table}), 1))
            """)
        except Exception as e:
            pass

    conn.commit()
    cursor.close()

def main():
    print("=" * 60)
    print("  BTRC QoS POC - Data Loader (Docker)")
    print("=" * 60)

    if not DATA_DIR.exists():
        print(f"Error: Data directory not found: {DATA_DIR}")
        return False

    print(f"\nConnecting to database: {DB_CONFIG['dbname']}@{DB_CONFIG['host']}...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        print("✓ Connected\n")
    except Exception as e:
        print(f"✗ Connection failed: {e}")
        return False

    def sort_key(x):
        if x.startswith('P.'):
            return '0' + x
        return '1' + x

    success_count = 0
    fail_count = 0

    for prefix in sorted(FILE_TABLE_MAP.keys(), key=sort_key):
        filepath = DATA_DIR / f"{prefix}.json"
        config = FILE_TABLE_MAP[prefix]

        if not filepath.exists():
            print(f"\n⚠ File not found: {filepath.name}")
            fail_count += 1
            continue

        print(f"\n[{prefix}]")
        try:
            data = load_json_file(filepath)
            if load_table(conn, config, data, prefix):
                success_count += 1
            else:
                fail_count += 1
        except Exception as e:
            print(f"  ✗ Error: {e}")
            fail_count += 1

    print("\nResetting sequences...")
    reset_sequences(conn)

    conn.close()

    print("\n" + "=" * 60)
    print(f"  Complete: {success_count} succeeded, {fail_count} failed")
    print("=" * 60)

    return fail_count == 0

if __name__ == '__main__':
    main()
