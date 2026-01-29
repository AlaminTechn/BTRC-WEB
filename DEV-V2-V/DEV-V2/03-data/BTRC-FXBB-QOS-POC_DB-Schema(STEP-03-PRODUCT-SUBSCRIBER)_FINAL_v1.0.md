# BTRC QoS Monitoring - Database Schema Design
## Step 3: Product/Subscriber Data (Packages, Tariffs, Subscribers)

| Metadata | Value |
|----------|-------|
| **Version** | 1.1 |
| **Status** | COMPLETED |
| **Created** | 2026-01-07 |
| **Updated** | 2026-01-12 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **Database** | PostgreSQL + TimescaleDB |

---

## 3.1 Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Subscriber Data Model | Monthly snapshots | ISP reports monthly; no real-time individual tracking |
| SNMP vs ISP Data | Separate storage | SNMP real-time data separate from ISP-reported snapshots |
| Package Coverage | Simple junction table | Basic many-to-many without complex metadata |
| Historical Packages | Separate history table | Track tariff changes over time |
| Bandwidth Snapshots | Monthly by package | Aggregate bandwidth allocation per package |

---

## 3.2 Table Definitions

### 3.2.1 package_types
Classification of broadband packages.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(20) | UNIQUE, NOT NULL | Type code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Description |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Default Values**: RESIDENTIAL, BUSINESS, ENTERPRISE, SOHO, DEDICATED

---

### 3.2.2 connection_types
Types of broadband connections.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(20) | UNIQUE, NOT NULL | Type code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Description |
| `technology` | VARCHAR(50) | | Underlying technology |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Default Values**: FIBER, DSL, CABLE, WIRELESS, DEDICATED_LEASED

---

### 3.2.3 packages
ISP broadband packages/tariffs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Owner ISP |
| `package_type_id` | INTEGER | FK → package_types.id | Package type |
| `connection_type_id` | INTEGER | FK → connection_types.id | Connection type |
| `code` | VARCHAR(50) | NOT NULL | Package code |
| `name_en` | VARCHAR(200) | NOT NULL | Package name (English) |
| `name_bn` | VARCHAR(200) | | Package name (Bengali) |
| `description` | TEXT | | Package description |
| `download_speed_mbps` | DECIMAL(10,2) | NOT NULL | Advertised download speed |
| `upload_speed_mbps` | DECIMAL(10,2) | NOT NULL | Advertised upload speed |
| `mir_mbps` | DECIMAL(10,2) | | Maximum Information Rate |
| `cir_mbps` | DECIMAL(10,2) | | Committed Information Rate |
| `data_cap_gb` | INTEGER | | Monthly data cap (NULL=unlimited) |
| `contention_ratio` | VARCHAR(20) | | Contention ratio (e.g., "1:8") |
| `monthly_price_bdt` | DECIMAL(10,2) | | Monthly price in BDT |
| `setup_fee_bdt` | DECIMAL(10,2) | | One-time setup fee |
| `is_fup_applicable` | BOOLEAN | DEFAULT false | Fair Usage Policy applies |
| `fup_threshold_gb` | INTEGER | | FUP threshold |
| `fup_reduced_speed_mbps` | DECIMAL(10,2) | | Speed after FUP |
| `min_contract_months` | INTEGER | | Minimum contract period |
| `launch_date` | DATE | | Package launch date |
| `discontinue_date` | DATE | | Package discontinuation date |
| `is_active` | BOOLEAN | DEFAULT true | Currently offered |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(isp_id, code)`

---

### 3.2.4 package_history
Historical tracking of package/tariff changes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `package_id` | INTEGER | FK → packages.id, NOT NULL | Parent package |
| `change_date` | DATE | NOT NULL | Effective date of change |
| `change_type` | VARCHAR(30) | NOT NULL | PRICE_CHANGE/SPEED_CHANGE/FUP_CHANGE/DISCONTINUE |
| `field_changed` | VARCHAR(50) | | Which field changed |
| `old_value` | TEXT | | Previous value |
| `new_value` | TEXT | | New value |
| `reason` | TEXT | | Reason for change |
| `approved_by` | INTEGER | FK → users.id | Approver |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

---

### 3.2.5 package_coverage
Simple junction table: packages available in geographic areas.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `package_id` | INTEGER | FK → packages.id, NOT NULL | Package |
| `district_id` | INTEGER | FK → geo_districts.id | Coverage district |
| `upazila_id` | INTEGER | FK → geo_upazilas.id | Coverage upazila |
| `is_available` | BOOLEAN | DEFAULT true | Currently available |
| `effective_date` | DATE | | Availability start date |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(package_id, district_id, upazila_id)`

---

### 3.2.6 subscriber_snapshots
Monthly subscriber count snapshots from ISP reports.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | ISP |
| `snapshot_month` | DATE | NOT NULL | Month (first day of month) |
| `package_id` | INTEGER | FK → packages.id | Specific package (optional) |
| `package_type_id` | INTEGER | FK → package_types.id | Package type (if not specific) |
| `connection_type_id` | INTEGER | FK → connection_types.id | Connection type |
| `district_id` | INTEGER | FK → geo_districts.id | Geographic breakdown |
| `total_subscribers` | INTEGER | NOT NULL | Total subscriber count |
| `new_subscribers` | INTEGER | | New subscribers this month |
| `churned_subscribers` | INTEGER | | Churned subscribers this month |
| `active_subscribers` | INTEGER | | Currently active |
| `suspended_subscribers` | INTEGER | | Temporarily suspended |
| `data_source` | VARCHAR(20) | DEFAULT 'ISP_API' | ISP_API/MANUAL/MIGRATED |
| `submission_id` | INTEGER | FK → api_submissions.id | Source submission |
| `is_verified` | BOOLEAN | DEFAULT false | BTRC verified |
| `verified_by` | INTEGER | FK → users.id | Verifier |
| `verified_at` | TIMESTAMPTZ | | Verification timestamp |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(isp_id, snapshot_month, package_id, district_id)`

---

### 3.2.7 bandwidth_snapshots
Monthly bandwidth allocation snapshots.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | ISP |
| `pop_id` | INTEGER | FK → pops.id | Specific PoP (optional) |
| `snapshot_month` | DATE | NOT NULL | Month (first day of month) |
| `total_international_mbps` | DECIMAL(12,2) | | Total international bandwidth |
| `total_bdix_mbps` | DECIMAL(12,2) | | Total BDIX bandwidth |
| `total_cache_mbps` | DECIMAL(12,2) | | Total cache/CDN bandwidth |
| `peak_utilization_pct` | DECIMAL(5,2) | | Peak utilization percentage |
| `avg_utilization_pct` | DECIMAL(5,2) | | Average utilization percentage |
| `data_source` | VARCHAR(20) | DEFAULT 'ISP_API' | ISP_API/SNMP_AGENT/MANUAL |
| `submission_id` | INTEGER | FK → api_submissions.id | Source submission |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(isp_id, pop_id, snapshot_month)`

---

## 3.3 Entity Relationship Summary

```
package_types
    └── packages
            ├── package_history
            ├── package_coverage
            └── subscriber_snapshots

connection_types
    └── packages

isps
    ├── packages
    ├── subscriber_snapshots
    └── bandwidth_snapshots
            └── pops (optional)
```

---

## 3.4 Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      ISP API Submission                          │
│                       (Monthly Report)                           │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
          ┌───────────────────────────────────┐
          │         subscriber_snapshots       │
          │  - By package, district, month     │
          │  - Total, new, churned counts      │
          └───────────────────────────────────┘
                          │
                          │  Cross-reference
                          ▼
          ┌───────────────────────────────────┐
          │      SNMP Real-time Data           │
          │  (ts_subscriber_counts hypertable) │
          │  - 5-minute intervals              │
          │  - Per-PoP active sessions         │
          └───────────────────────────────────┘
```

---

## 3.5 Table Count Summary

| Table | Expected Records | Growth Rate |
|-------|------------------|-------------|
| package_types | ~5 | Static |
| connection_types | ~5 | Static |
| packages | ~15,000 | Low |
| package_history | ~50,000/year | Medium |
| package_coverage | ~100,000 | Low |
| subscriber_snapshots | ~200,000/year | Medium |
| bandwidth_snapshots | ~60,000/year | Medium |

---

**End of Step 3 Documentation**
