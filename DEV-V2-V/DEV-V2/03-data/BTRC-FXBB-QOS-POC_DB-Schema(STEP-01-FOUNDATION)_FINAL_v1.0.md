# BTRC QoS Monitoring - Database Schema Design
## Step 1: Foundation Entities (Geographic, ISP, License)

| Metadata | Value |
|----------|-------|
| **Version** | 1.1 |
| **Status** | COMPLETED |
| **Created** | 2026-01-07 |
| **Updated** | 2026-01-12 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **Database** | PostgreSQL + TimescaleDB |

---

## 1.1 Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Geographic Levels | All 4 levels (Division → District → Upazila → Thana) | Complete administrative hierarchy for Bangladesh |
| **Geographic Identifier** | **BBS Geocode System** | Official Bangladesh Bureau of Statistics codes; aligns with BTRC reporting standards |
| Spatial Data | Just lat/lng (no PostGIS) | Simplicity; PostGIS can be added later |
| ISP History Tracking | Separate `isp_history` table | Temporal tracking without cluttering main ISP table |
| Audit Columns | Yes | `created_at`, `updated_at`, `created_by`, `updated_by` |
| Soft Delete | Yes | `deleted_at` column for recoverable deletion |
| Multi-tenancy | Yes | `tenant_id` where applicable |
| Localization | Yes | `_bn` suffix for Bengali fields |

> **📋 Review Note**: PostGIS can be integrated later if advanced spatial queries (distance calculations, polygon containment) become necessary.

---

## 1.1.1 BBS Geocode Standard

The database uses the **Bangladesh Bureau of Statistics (BBS)** geocode system as the standard geographic identifier.

### Code Structure

| Level | Format | Digits | Example | Description |
|-------|--------|--------|---------|-------------|
| Division | `DD` | 2 | `30` | Dhaka Division |
| District | `DDDD` | 4 | `3026` | Dhaka District (30) + District code (26) |
| Upazila | `DDDDUU` | 6 | `302614` | District (3026) + Upazila code (14) |
| Thana | `DDDDUU##` | 8 | `30261401` | Upazila (302614) + Thana code (01) |

### Division Codes (8 Divisions)

| BBS Code | Division | Bengali |
|----------|----------|---------|
| `10` | Barishal | বরিশাল |
| `20` | Chattogram | চট্টগ্রাম |
| `30` | Dhaka | ঢাকা |
| `40` | Khulna | খুলনা |
| `50` | Rajshahi | রাজশাহী |
| `55` | Rangpur | রংপুর |
| `60` | Sylhet | সিলেট |
| `65` | Mymensingh | ময়মনসিংহ |

### Benefits of BBS Codes

1. **Official Standard**: Used by all government agencies including BTRC
2. **Hierarchical**: Parent codes can be derived by truncation (e.g., `302614` → `3026` → `30`)
3. **Compact**: Single field stores complete location reference
4. **Interoperable**: Easy data exchange with other government systems
5. **API-Friendly**: Simple string matching for location filtering

---

## 1.2 Table Definitions

### 1.2.1 geo_divisions
Top-level administrative unit (8 divisions in Bangladesh).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `bbs_code` | CHAR(2) | UNIQUE, NOT NULL | BBS division code (e.g., "30" for Dhaka) |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `latitude` | DECIMAL(10,8) | | Center latitude |
| `longitude` | DECIMAL(11,8) | | Center longitude |
| `govt_url` | VARCHAR(255) | | Official govt website URL |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(bbs_code)`

---

### 1.2.2 geo_districts
Second-level administrative unit (64 districts).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `division_id` | INTEGER | FK → geo_divisions.id, NOT NULL | Parent division |
| `bbs_code` | CHAR(4) | UNIQUE, NOT NULL | Full BBS code (division+district, e.g., "3026") |
| `district_code` | CHAR(2) | NOT NULL | District-only portion (e.g., "26") |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `latitude` | DECIMAL(10,8) | | Center latitude |
| `longitude` | DECIMAL(11,8) | | Center longitude |
| `govt_url` | VARCHAR(255) | | Official govt website URL |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(bbs_code)`, `INDEX(division_id)`

**Note**: `bbs_code` = division.bbs_code + district_code (validated by CHECK constraint or trigger)

---

### 1.2.3 geo_upazilas
Third-level administrative unit (495 upazilas).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `district_id` | INTEGER | FK → geo_districts.id, NOT NULL | Parent district |
| `bbs_code` | CHAR(6) | UNIQUE, NOT NULL | Full BBS code (division+district+upazila, e.g., "302614") |
| `upazila_code` | CHAR(2) | NOT NULL | Upazila-only portion (e.g., "14") |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `latitude` | DECIMAL(10,8) | | Center latitude |
| `longitude` | DECIMAL(11,8) | | Center longitude |
| `govt_url` | VARCHAR(255) | | Official govt website URL |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(bbs_code)`, `INDEX(district_id)`

**Note**: `bbs_code` = district.bbs_code + upazila_code (validated by CHECK constraint or trigger)

---

### 1.2.4 geo_thanas
Fourth-level administrative unit (police stations/thanas).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `upazila_id` | INTEGER | FK → geo_upazilas.id, NOT NULL | Parent upazila |
| `bbs_code` | CHAR(8) | UNIQUE, NOT NULL | Full BBS code (div+dist+upz+thana, e.g., "30261401") |
| `thana_code` | CHAR(2) | NOT NULL | Thana-only portion (e.g., "01") |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `latitude` | DECIMAL(10,8) | | Center latitude |
| `longitude` | DECIMAL(11,8) | | Center longitude |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

**Index**: `UNIQUE(bbs_code)`, `INDEX(upazila_id)`

**Note**: `bbs_code` = upazila.bbs_code + thana_code (validated by CHECK constraint or trigger)

---

### 1.2.5 isp_license_categories
ISP license types as per BTRC classification.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(20) | UNIQUE, NOT NULL | Category code (e.g., "NATIONWIDE") |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Category description |
| `min_bandwidth_mbps` | INTEGER | | Minimum bandwidth requirement |
| `coverage_scope` | VARCHAR(50) | | Geographic scope (nationwide/regional/local) |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

---

### 1.2.6 isps
Master table for Internet Service Providers.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `btrc_license_no` | VARCHAR(50) | UNIQUE, NOT NULL | BTRC license number |
| `name_en` | VARCHAR(200) | NOT NULL | Company name (English) |
| `name_bn` | VARCHAR(200) | | Company name (Bengali) |
| `trade_name` | VARCHAR(200) | | Trading/brand name |
| `license_category_id` | INTEGER | FK → isp_license_categories.id | License category |
| `license_issue_date` | DATE | | License issue date |
| `license_expiry_date` | DATE | | License expiry date |
| `license_status` | VARCHAR(20) | DEFAULT 'ACTIVE' | ACTIVE/SUSPENDED/REVOKED/EXPIRED |
| `headquarters_district_id` | INTEGER | FK → geo_districts.id | HQ location |
| `address` | TEXT | | Full address |
| `website` | VARCHAR(255) | | Company website |
| `email` | VARCHAR(255) | | Primary email |
| `phone` | VARCHAR(50) | | Primary phone |
| `total_subscribers` | INTEGER | DEFAULT 0 | Current subscriber count |
| `total_bandwidth_gbps` | DECIMAL(10,2) | | Total capacity |
| `api_enabled` | BOOLEAN | DEFAULT false | API integration status |
| `api_key_hash` | VARCHAR(255) | | Hashed API key |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator user |
| `updated_by` | INTEGER | FK → users.id | Last updater |
| `deleted_at` | TIMESTAMPTZ | | Soft delete timestamp |

---

### 1.2.7 isp_coverage_areas
ISP geographic coverage mapping.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Parent ISP |
| `division_id` | INTEGER | FK → geo_divisions.id | Coverage at division level |
| `district_id` | INTEGER | FK → geo_districts.id | Coverage at district level |
| `upazila_id` | INTEGER | FK → geo_upazilas.id | Coverage at upazila level |
| `thana_id` | INTEGER | FK → geo_thanas.id | Coverage at thana level |
| `coverage_type` | VARCHAR(20) | DEFAULT 'FULL' | FULL/PARTIAL/PLANNED |
| `subscriber_count` | INTEGER | | Subscribers in this area |
| `effective_date` | DATE | | Coverage start date |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(isp_id, division_id, district_id, upazila_id, thana_id)`

---

### 1.2.8 isp_contacts
ISP contact persons for different purposes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Parent ISP |
| `contact_type` | VARCHAR(30) | NOT NULL | TECHNICAL/BILLING/MANAGEMENT/NOC |
| `name` | VARCHAR(100) | NOT NULL | Contact person name |
| `designation` | VARCHAR(100) | | Job title |
| `email` | VARCHAR(255) | | Email address |
| `phone` | VARCHAR(50) | | Phone number |
| `is_primary` | BOOLEAN | DEFAULT false | Primary contact for this type |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

---

### 1.2.9 isp_history
Temporal tracking of ISP changes (separate table approach).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Parent ISP |
| `change_type` | VARCHAR(30) | NOT NULL | LICENSE_RENEWAL/STATUS_CHANGE/MERGER/ACQUISITION |
| `change_date` | DATE | NOT NULL | Effective date of change |
| `field_changed` | VARCHAR(50) | | Which field changed |
| `old_value` | TEXT | | Previous value |
| `new_value` | TEXT | | New value |
| `reference_document` | VARCHAR(255) | | Supporting document reference |
| `notes` | TEXT | | Additional notes |
| `recorded_by` | INTEGER | FK → users.id | Who recorded this |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

---

## 1.3 Entity Relationship Summary

```
geo_divisions (8)
    └── geo_districts (64)
            └── geo_upazilas (495)
                    └── geo_thanas (~600)

isp_license_categories
    └── isps (1,500+)
            ├── isp_coverage_areas
            ├── isp_contacts
            └── isp_history
```

---

## 1.4 Table Count Summary

| Table | Expected Records | Growth Rate |
|-------|------------------|-------------|
| geo_divisions | 8 | Static |
| geo_districts | 64 | Static |
| geo_upazilas | 495 | Static |
| geo_thanas | ~600 | Static |
| isp_license_categories | ~10 | Low |
| isps | 1,500+ | Low |
| isp_coverage_areas | ~10,000 | Low |
| isp_contacts | ~5,000 | Low |
| isp_history | ~20,000/year | Medium |

---

## 1.5 BBS Code Usage Patterns

### 1.5.1 Lookup Functions

```sql
-- Find division from any BBS code
CREATE OR REPLACE FUNCTION get_division_from_bbs(p_bbs_code VARCHAR)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT id FROM geo_divisions WHERE bbs_code = LEFT(p_bbs_code, 2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Find district from any BBS code (4+ digits)
CREATE OR REPLACE FUNCTION get_district_from_bbs(p_bbs_code VARCHAR)
RETURNS INTEGER AS $$
BEGIN
    IF LENGTH(p_bbs_code) < 4 THEN RETURN NULL; END IF;
    RETURN (SELECT id FROM geo_districts WHERE bbs_code = LEFT(p_bbs_code, 4));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Find upazila from BBS code (6+ digits)
CREATE OR REPLACE FUNCTION get_upazila_from_bbs(p_bbs_code VARCHAR)
RETURNS INTEGER AS $$
BEGIN
    IF LENGTH(p_bbs_code) < 6 THEN RETURN NULL; END IF;
    RETURN (SELECT id FROM geo_upazilas WHERE bbs_code = LEFT(p_bbs_code, 6));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Resolve BBS code to full location hierarchy
CREATE OR REPLACE FUNCTION resolve_bbs_code(p_bbs_code VARCHAR)
RETURNS TABLE(
    division_id INT, division_name VARCHAR,
    district_id INT, district_name VARCHAR,
    upazila_id INT, upazila_name VARCHAR,
    thana_id INT, thana_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.name_en,
        di.id, di.name_en,
        u.id, u.name_en,
        t.id, t.name_en
    FROM geo_divisions d
    LEFT JOIN geo_districts di ON di.bbs_code = LEFT(p_bbs_code, 4)
    LEFT JOIN geo_upazilas u ON u.bbs_code = LEFT(p_bbs_code, 6)
    LEFT JOIN geo_thanas t ON t.bbs_code = p_bbs_code
    WHERE d.bbs_code = LEFT(p_bbs_code, 2);
END;
$$ LANGUAGE plpgsql STABLE;
```

### 1.5.2 API Data Format

When ISPs submit data via API, they use BBS codes for geographic references:

```json
{
  "isp_id": "ISP-001",
  "submission_type": "SUBSCRIBER_DATA",
  "data": {
    "period": "2026-01",
    "subscribers_by_location": [
      {
        "bbs_code": "302614",
        "subscriber_count": 1250,
        "package_breakdown": {...}
      },
      {
        "bbs_code": "302633",
        "subscriber_count": 890,
        "package_breakdown": {...}
      }
    ]
  }
}
```

### 1.5.3 Validation Rules

```sql
-- Validate BBS code format
CREATE OR REPLACE FUNCTION is_valid_bbs_code(p_bbs_code VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    -- Must be 2, 4, 6, or 8 digits
    IF LENGTH(p_bbs_code) NOT IN (2, 4, 6, 8) THEN
        RETURN FALSE;
    END IF;

    -- Must be all digits
    IF p_bbs_code !~ '^[0-9]+$' THEN
        RETURN FALSE;
    END IF;

    -- Division must exist
    IF NOT EXISTS (SELECT 1 FROM geo_divisions WHERE bbs_code = LEFT(p_bbs_code, 2)) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql STABLE;
```

### 1.5.4 Index Strategy for BBS Code Queries

```sql
-- Fast prefix searches (all subscribers in Dhaka division)
CREATE INDEX idx_districts_division_prefix ON geo_districts (LEFT(bbs_code, 2));
CREATE INDEX idx_upazilas_district_prefix ON geo_upazilas (LEFT(bbs_code, 4));

-- Example: Get all upazilas in Dhaka division (code starts with "30")
SELECT * FROM geo_upazilas WHERE bbs_code LIKE '30%';

-- Example: Get all thanas in a specific district
SELECT * FROM geo_thanas WHERE bbs_code LIKE '3026%';
```

---

## 1.6 Data Source Reference

Geographic data sourced from:
- **Bangladesh Bureau of Statistics (BBS)** - Official geocode system
- **Reference File**: `_RESEARCH/other/BBS-Geocode-Bangladesh-Reference.md`
- **Data Files**:
  - `BBS-Geocode-Divisions.json` (8 divisions)
  - `BBS-Geocode-Districts.json` (64 districts)
  - `BBS-Geocode-Upazilas.json` (494 upazilas)

---

**End of Step 1 Documentation**
