# BTRC QoS Monitoring - Database Schema Design
## Step 2: Infrastructure Entities (PoPs, Agents, SNMP Config)

| Metadata | Value |
|----------|-------|
| **Version** | 1.1 |
| **Status** | COMPLETED |
| **Created** | 2026-01-07 |
| **Updated** | 2026-01-12 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **Database** | PostgreSQL + TimescaleDB |

---

## 2.1 Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Hardware Probes | **EXCLUDED** | Mistakenly included in PRD - ignored entirely |
| PoP Interconnections | **Removed** | Parent-child hierarchy via `parent_pop_id` sufficient |
| SNMP Architecture | **PoP-centric** | Interface counters per upstream type, not device-centric |
| Agent-PoP Relationship | 1:1 or 1:N | Agent can serve multiple PoPs (hub ISP scenarios) |
| Network Elements | Simplified | Inventory tracking only, not full SNMP discovery |
| Interface Types | INTERNET, BDIX, CACHE, DOWNSTREAM | Four key upstream/downstream types |
| Subscriber Count Source | BRAS/Radius/Billing | Custom/enterprise MIB polling |
| Poll Interval | 5 minutes | SNMP polling frequency |
| Submission Interval | 15 minutes | Data batching to central system |

> **⚠️ Important**: Hardware probes were mistakenly included in PRD v3.0-BETA. This schema excludes all hardware probe references.

---

## 2.2 Table Definitions

### 2.2.1 pop_categories
Classification of Points of Presence.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(20) | UNIQUE, NOT NULL | Category code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Category description |
| `tier_level` | INTEGER | | Tier level (1=Core, 2=Distribution, 3=Access) |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Example Categories**: CORE_DC, REGIONAL_POP, EDGE_POP, IXP_INTERCONNECT, BDIX_POP

---

### 2.2.2 pops
Points of Presence for ISPs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Owner ISP |
| `category_id` | INTEGER | FK → pop_categories.id | PoP category |
| `parent_pop_id` | INTEGER | FK → pops.id | Parent PoP (hierarchy) |
| `code` | VARCHAR(50) | NOT NULL | Unique PoP code |
| `name_en` | VARCHAR(200) | NOT NULL | English name |
| `name_bn` | VARCHAR(200) | | Bengali name |
| `district_id` | INTEGER | FK → geo_districts.id | Location district |
| `upazila_id` | INTEGER | FK → geo_upazilas.id | Location upazila |
| `address` | TEXT | | Physical address |
| `latitude` | DECIMAL(10,8) | | GPS latitude |
| `longitude` | DECIMAL(11,8) | | GPS longitude |
| `total_capacity_mbps` | DECIMAL(12,2) | | Total bandwidth capacity (Mbps) |
| `subscriber_capacity` | INTEGER | | Max subscriber capacity |
| `commissioned_date` | DATE | | Go-live date |
| `status` | VARCHAR(20) | DEFAULT 'ACTIVE' | ACTIVE/MAINTENANCE/DECOMMISSIONED |
| `snmp_enabled` | BOOLEAN | DEFAULT false | SNMP monitoring enabled |
| `agent_id` | INTEGER | FK → software_agents.id | Assigned monitoring agent |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(isp_id, code)`

---

### 2.2.3 network_elements
Simplified network device inventory (not full SNMP discovery).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `pop_id` | INTEGER | FK → pops.id, NOT NULL | Parent PoP |
| `device_type` | VARCHAR(30) | NOT NULL | ROUTER/SWITCH/BRAS/OLT/FIREWALL |
| `hostname` | VARCHAR(100) | | Device hostname |
| `management_ip` | INET | | Management IP address |
| `vendor` | VARCHAR(50) | | Device vendor |
| `model` | VARCHAR(100) | | Device model |
| `serial_number` | VARCHAR(100) | | Serial number |
| `snmp_community` | VARCHAR(100) | | SNMP community (encrypted) |
| `snmp_version` | VARCHAR(10) | DEFAULT 'v2c' | v1/v2c/v3 |
| `is_monitored` | BOOLEAN | DEFAULT false | SNMP monitoring enabled |
| `status` | VARCHAR(20) | DEFAULT 'ACTIVE' | ACTIVE/MAINTENANCE/DECOMMISSIONED |
| `notes` | TEXT | | Additional notes |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

---

### 2.2.4 software_agents
Docker-based monitoring agents (SNMP Agent, QoS Agent).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Owner ISP |
| `agent_type` | VARCHAR(20) | NOT NULL | SNMP_AGENT/QOS_AGENT |
| `agent_uuid` | UUID | UNIQUE, NOT NULL | Unique agent identifier |
| `name` | VARCHAR(100) | NOT NULL | Agent name |
| `description` | TEXT | | Agent description |
| `version` | VARCHAR(20) | | Current software version |
| `host_ip` | INET | | Host machine IP |
| `container_id` | VARCHAR(100) | | Docker container ID |
| `last_heartbeat` | TIMESTAMPTZ | | Last heartbeat timestamp |
| `heartbeat_interval_sec` | INTEGER | DEFAULT 60 | Expected heartbeat interval |
| `poll_interval_sec` | INTEGER | DEFAULT 300 | SNMP poll interval (5 min) |
| `submission_interval_sec` | INTEGER | DEFAULT 900 | Data submission interval (15 min) |
| `config_json` | JSONB | | Agent configuration |
| `status` | VARCHAR(20) | DEFAULT 'INACTIVE' | ACTIVE/INACTIVE/ERROR/MAINTENANCE |
| `status_message` | TEXT | | Status details |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

---

### 2.2.5 agent_pop_assignments
Many-to-many relationship: Agent can serve multiple PoPs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `agent_id` | INTEGER | FK → software_agents.id, NOT NULL | Agent |
| `pop_id` | INTEGER | FK → pops.id, NOT NULL | PoP |
| `is_primary` | BOOLEAN | DEFAULT true | Primary agent for this PoP |
| `assignment_date` | DATE | | When assigned |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(agent_id, pop_id)`

---

### 2.2.6 upstream_types
Reference table for interface/upstream classifications.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(20) | UNIQUE, NOT NULL | Type code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Description |
| `direction` | VARCHAR(10) | NOT NULL | UPSTREAM/DOWNSTREAM/BOTH |
| `display_order` | INTEGER | | UI display order |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Default Values**:
| Code | Name | Direction |
|------|------|-----------|
| INTERNET | International Gateway | UPSTREAM |
| BDIX | BDIX Peering | UPSTREAM |
| CACHE | CDN/Cache | UPSTREAM |
| DOWNSTREAM | Subscriber Facing | DOWNSTREAM |

---

### 2.2.7 snmp_targets
SNMP polling targets at PoP level (PoP-centric design).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `pop_id` | INTEGER | FK → pops.id, NOT NULL | Target PoP |
| `upstream_type_id` | INTEGER | FK → upstream_types.id, NOT NULL | Interface type |
| `target_ip` | INET | NOT NULL | SNMP target IP |
| `snmp_port` | INTEGER | DEFAULT 161 | SNMP port |
| `snmp_version` | VARCHAR(10) | DEFAULT 'v2c' | v1/v2c/v3 |
| `snmp_community` | VARCHAR(100) | | Community string (encrypted) |
| `snmp_v3_user` | VARCHAR(100) | | SNMPv3 username |
| `snmp_v3_auth_protocol` | VARCHAR(10) | | MD5/SHA |
| `snmp_v3_auth_key` | VARCHAR(255) | | Auth key (encrypted) |
| `snmp_v3_priv_protocol` | VARCHAR(10) | | DES/AES |
| `snmp_v3_priv_key` | VARCHAR(255) | | Privacy key (encrypted) |
| `if_index` | INTEGER | | Interface index for counters |
| `if_name` | VARCHAR(100) | | Interface name |
| `if_description` | VARCHAR(255) | | Interface description |
| `if_speed_mbps` | INTEGER | | Interface speed in Mbps |
| `oid_in_octets` | VARCHAR(100) | DEFAULT '.1.3.6.1.2.1.2.2.1.10' | Inbound octets OID |
| `oid_out_octets` | VARCHAR(100) | DEFAULT '.1.3.6.1.2.1.2.2.1.16' | Outbound octets OID |
| `oid_in_errors` | VARCHAR(100) | | Inbound errors OID |
| `oid_out_errors` | VARCHAR(100) | | Outbound errors OID |
| `counter_bits` | INTEGER | DEFAULT 64 | 32 or 64 bit counters |
| `is_enabled` | BOOLEAN | DEFAULT true | Polling enabled |
| `last_poll_time` | TIMESTAMPTZ | | Last successful poll |
| `last_poll_status` | VARCHAR(20) | | SUCCESS/TIMEOUT/ERROR |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(pop_id, upstream_type_id, target_ip, if_index)`

> **📋 Review Note**: For legacy devices with 32-bit counters, ensure agent handles counter wrapping properly (especially at high speeds where wrap can occur within poll interval).

---

### 2.2.8 subscriber_count_sources
Configuration for subscriber count polling from BRAS/Radius/Billing.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `pop_id` | INTEGER | FK → pops.id, NOT NULL | Target PoP |
| `source_type` | VARCHAR(20) | NOT NULL | BRAS/RADIUS/BILLING/SNMP_MIB |
| `target_ip` | INET | | Target IP (if SNMP-based) |
| `snmp_port` | INTEGER | DEFAULT 161 | SNMP port |
| `snmp_community` | VARCHAR(100) | | Community string (encrypted) |
| `oid_active_sessions` | VARCHAR(100) | | OID for active session count |
| `oid_pppoe_sessions` | VARCHAR(100) | | OID for PPPoE sessions |
| `custom_mib_name` | VARCHAR(100) | | Custom/enterprise MIB name |
| `query_method` | VARCHAR(20) | | SNMP/API/DB_QUERY |
| `api_endpoint` | VARCHAR(255) | | API endpoint if applicable |
| `db_connection_string` | TEXT | | DB connection (encrypted) |
| `db_query` | TEXT | | SQL query for subscriber count |
| `is_enabled` | BOOLEAN | DEFAULT true | Polling enabled |
| `poll_interval_sec` | INTEGER | DEFAULT 300 | Poll interval |
| `last_poll_time` | TIMESTAMPTZ | | Last successful poll |
| `last_poll_status` | VARCHAR(20) | | SUCCESS/TIMEOUT/ERROR |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

---

### 2.2.9 test_target_categories
Categories for QoS test targets.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(30) | UNIQUE, NOT NULL | Category code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Description |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Default Categories**: INTERNATIONAL_CDN, BDIX_PEER, GOVT_PORTAL, BANKING, SOCIAL_MEDIA, GAMING

---

### 2.2.10 test_targets
Shared test targets for QoS synthetic testing.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `category_id` | INTEGER | FK → test_target_categories.id | Target category |
| `name` | VARCHAR(100) | NOT NULL | Target name |
| `description` | TEXT | | Target description |
| `target_type` | VARCHAR(20) | NOT NULL | ICMP/HTTP/HTTPS/DNS/SPEEDTEST |
| `target_host` | VARCHAR(255) | NOT NULL | Hostname or IP |
| `target_port` | INTEGER | | Port (if applicable) |
| `target_url` | VARCHAR(500) | | Full URL (for HTTP tests) |
| `expected_response` | VARCHAR(255) | | Expected response for validation |
| `timeout_ms` | INTEGER | DEFAULT 5000 | Test timeout in ms |
| `is_bdix` | BOOLEAN | DEFAULT false | Is BDIX-local target |
| `is_international` | BOOLEAN | DEFAULT false | Is international target |
| `priority` | INTEGER | DEFAULT 5 | Test priority (1=highest) |
| `is_enabled` | BOOLEAN | DEFAULT true | Target enabled for testing |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

---

## 2.3 Entity Relationship Summary

```
software_agents (SNMP_AGENT / QOS_AGENT)
    └── agent_pop_assignments (1:N or 1:1)
            └── pops
                    ├── pop_categories
                    ├── network_elements (inventory)
                    ├── snmp_targets (PoP-centric polling)
                    │       └── upstream_types
                    └── subscriber_count_sources

test_target_categories
    └── test_targets (shared across all agents)
```

---

## 2.4 SNMP Polling Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SNMP DOCKER AGENT                            │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Interface   │    │  Subscriber  │    │   Heartbeat  │       │
│  │  Counters    │    │    Counts    │    │   & Status   │       │
│  │  (5 min)     │    │   (5 min)    │    │   (1 min)    │       │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘       │
│         │                   │                   │                │
│         └───────────────────┴───────────────────┘                │
│                             │                                    │
│                    ┌────────▼────────┐                          │
│                    │  Data Batcher   │                          │
│                    │  (15 min batch) │                          │
│                    └────────┬────────┘                          │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Central BTRC   │
                    │     System      │
                    └─────────────────┘

Per PoP Interface Types:
  - INTERNET (International Gateway)
  - BDIX (Bangladesh IX Peering)
  - CACHE (CDN/Cache servers)
  - DOWNSTREAM (Subscriber-facing)

Subscriber Count Sources:
  - BRAS active PPPoE sessions
  - RADIUS active sessions
  - Billing system active accounts
  - Custom enterprise MIB
```

---

## 2.5 Table Count Summary

| Table | Expected Records | Growth Rate |
|-------|------------------|-------------|
| pop_categories | ~10 | Static |
| pops | ~5,000 | Low |
| network_elements | ~15,000 | Low |
| software_agents | ~3,000 | Low |
| agent_pop_assignments | ~5,000 | Low |
| upstream_types | 4 | Static |
| snmp_targets | ~20,000 | Low |
| subscriber_count_sources | ~5,000 | Low |
| test_target_categories | ~10 | Static |
| test_targets | ~100 | Low |

---

**End of Step 2 Documentation**
