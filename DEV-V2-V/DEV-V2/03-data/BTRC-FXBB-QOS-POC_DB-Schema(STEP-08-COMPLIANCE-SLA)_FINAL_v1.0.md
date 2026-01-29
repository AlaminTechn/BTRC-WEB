# BTRC QoS Monitoring - Database Schema Design
## Step 8: Compliance & SLA

| Metadata | Value |
|----------|-------|
| **Version** | 1.0 |
| **Status** | COMPLETED |
| **Created** | 2026-01-07 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **Database** | PostgreSQL + TimescaleDB |

---

## 8.1 Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Violation Detection | Automated | System detects violations from QoS data |
| Compliance Score Calculation | Monthly | Calculated monthly from violations and metrics |
| Compliance History Retention | 1 year detailed, 3 years summary | Balance storage with audit needs |

> **📋 Review Note**: Consider semi-automated violation detection where system flags potential violations for human review before final determination. This may be important for disputed violations or edge cases.

---

## 8.2 Table Definitions

### 8.2.1 qos_parameters
BTRC-defined QoS parameters and standards.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(30) | UNIQUE, NOT NULL | Parameter code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Parameter description |
| `category` | VARCHAR(30) | | SPEED/LATENCY/AVAILABILITY/PACKET_LOSS |
| `unit` | VARCHAR(20) | | Measurement unit (Mbps, ms, %) |
| `measurement_method` | VARCHAR(50) | | How measured |
| `data_source` | VARCHAR(20) | | SNMP_AGENT/QOS_AGENT/MOBILE_APP/ISP_API |
| `is_mandatory` | BOOLEAN | DEFAULT true | Required for compliance |
| `weight` | DECIMAL(3,2) | DEFAULT 1.00 | Weight in compliance score |
| `effective_date` | DATE | | When parameter became effective |
| `superseded_date` | DATE | | When superseded |
| `btrc_regulation_ref` | VARCHAR(100) | | BTRC regulation reference |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Default Parameters**:
| Code | Name | Category | Unit |
|------|------|----------|------|
| MIN_DOWNLOAD_SPEED | Minimum Download Speed | SPEED | Mbps |
| MIN_UPLOAD_SPEED | Minimum Upload Speed | SPEED | Mbps |
| MAX_LATENCY_DOMESTIC | Maximum Domestic Latency | LATENCY | ms |
| MAX_LATENCY_INTL | Maximum International Latency | LATENCY | ms |
| MIN_AVAILABILITY | Minimum Service Availability | AVAILABILITY | % |
| MAX_PACKET_LOSS | Maximum Packet Loss | PACKET_LOSS | % |

---

### 8.2.2 sla_thresholds
SLA thresholds by ISP license category and package type.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `qos_parameter_id` | INTEGER | FK → qos_parameters.id, NOT NULL | QoS parameter |
| `license_category_id` | INTEGER | FK → isp_license_categories.id | ISP license type (optional) |
| `package_type_id` | INTEGER | FK → package_types.id | Package type (optional) |
| `threshold_type` | VARCHAR(20) | NOT NULL | MIN/MAX/RANGE |
| `threshold_value` | DECIMAL(10,4) | NOT NULL | Threshold value |
| `threshold_value_max` | DECIMAL(10,4) | | Upper bound (for RANGE) |
| `warning_threshold` | DECIMAL(10,4) | | Warning level (before violation) |
| `measurement_period` | VARCHAR(20) | DEFAULT 'MONTHLY' | HOURLY/DAILY/WEEKLY/MONTHLY |
| `min_samples_required` | INTEGER | DEFAULT 100 | Minimum samples for validity |
| `effective_date` | DATE | NOT NULL | When effective |
| `expiry_date` | DATE | | Expiration date |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator |

**Index**: `UNIQUE(qos_parameter_id, license_category_id, package_type_id, effective_date)`

---

### 8.2.3 sla_violations
Detected SLA violations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `violation_uuid` | UUID | UNIQUE, NOT NULL | Unique violation ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | Violating ISP |
| `pop_id` | INTEGER | FK → pops.id | Specific PoP (if applicable) |
| `qos_parameter_id` | INTEGER | FK → qos_parameters.id, NOT NULL | Violated parameter |
| `sla_threshold_id` | INTEGER | FK → sla_thresholds.id | Threshold violated |
| `violation_type` | VARCHAR(20) | NOT NULL | THRESHOLD_BREACH/AVAILABILITY/REPORTING |
| `severity` | VARCHAR(20) | DEFAULT 'MEDIUM' | LOW/MEDIUM/HIGH/CRITICAL |
| `detection_method` | VARCHAR(30) | NOT NULL | AUTOMATED/MANUAL/FIELD_INSPECTION |
| `detection_time` | TIMESTAMPTZ | NOT NULL | When detected |
| `violation_start` | TIMESTAMPTZ | | Violation start time |
| `violation_end` | TIMESTAMPTZ | | Violation end time |
| `measurement_period_start` | DATE | | Measurement period start |
| `measurement_period_end` | DATE | | Measurement period end |
| `expected_value` | DECIMAL(10,4) | | Expected threshold value |
| `actual_value` | DECIMAL(10,4) | | Actual measured value |
| `deviation_pct` | DECIMAL(6,2) | | Deviation percentage |
| `sample_count` | INTEGER | | Number of samples |
| `affected_subscribers_est` | INTEGER | | Estimated affected subscribers |
| `evidence_summary` | TEXT | | Summary of evidence |
| `evidence_data` | JSONB | | Detailed evidence data |
| `status` | VARCHAR(20) | DEFAULT 'DETECTED' | DETECTED/NOTIFIED/ACKNOWLEDGED/DISPUTED/CONFIRMED/RESOLVED/WAIVED |
| `isp_notified_at` | TIMESTAMPTZ | | ISP notification time |
| `isp_response` | TEXT | | ISP response |
| `isp_response_at` | TIMESTAMPTZ | | Response timestamp |
| `dispute_reason` | TEXT | | Dispute reason (if disputed) |
| `resolution_notes` | TEXT | | Resolution notes |
| `resolved_at` | TIMESTAMPTZ | | Resolution timestamp |
| `resolved_by` | INTEGER | FK → users.id | Resolver |
| `penalty_applicable` | BOOLEAN | DEFAULT false | Penalty applies |
| `penalty_rule_id` | INTEGER | FK → penalty_rules.id | Applicable penalty |
| `penalty_amount_bdt` | DECIMAL(15,2) | | Penalty amount |
| `penalty_status` | VARCHAR(20) | | PENDING/INVOICED/PAID/WAIVED |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator (system or user) |
| `updated_by` | INTEGER | FK → users.id | Last updater |

**Indexes**:
- `idx_violations_isp_status` ON (isp_id, status)
- `idx_violations_detection` ON (detection_time DESC)
- `idx_violations_parameter` ON (qos_parameter_id, detection_time DESC)

---

### 8.2.4 compliance_scores
Monthly compliance scores by ISP.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | ISP |
| `score_month` | DATE | NOT NULL | Month (first day) |
| `overall_score` | DECIMAL(5,2) | | Overall compliance score (0-100) |
| `speed_score` | DECIMAL(5,2) | | Speed compliance score |
| `latency_score` | DECIMAL(5,2) | | Latency compliance score |
| `availability_score` | DECIMAL(5,2) | | Availability score |
| `reporting_score` | DECIMAL(5,2) | | Reporting compliance score |
| `total_violations` | INTEGER | DEFAULT 0 | Total violations |
| `critical_violations` | INTEGER | DEFAULT 0 | Critical violations |
| `high_violations` | INTEGER | DEFAULT 0 | High severity violations |
| `medium_violations` | INTEGER | DEFAULT 0 | Medium violations |
| `low_violations` | INTEGER | DEFAULT 0 | Low violations |
| `resolved_violations` | INTEGER | DEFAULT 0 | Resolved violations |
| `avg_resolution_hours` | DECIMAL(10,2) | | Average resolution time |
| `compliance_rank` | INTEGER | | Rank among all ISPs |
| `compliance_tier` | VARCHAR(20) | | EXCELLENT/GOOD/SATISFACTORY/NEEDS_IMPROVEMENT/NON_COMPLIANT |
| `trend_direction` | VARCHAR(10) | | UP/DOWN/STABLE |
| `trend_change_pct` | DECIMAL(5,2) | | Change from previous month |
| `calculation_time` | TIMESTAMPTZ | DEFAULT NOW() | When calculated |
| `calculation_notes` | TEXT | | Calculation notes |
| `is_finalized` | BOOLEAN | DEFAULT false | Score finalized |
| `finalized_by` | INTEGER | FK → users.id | Finalizer |
| `finalized_at` | TIMESTAMPTZ | | Finalization timestamp |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(isp_id, score_month)`

**Compliance Tiers**:
| Tier | Score Range | Description |
|------|-------------|-------------|
| EXCELLENT | 95-100 | Exemplary compliance |
| GOOD | 85-94 | Above average |
| SATISFACTORY | 70-84 | Meets minimum requirements |
| NEEDS_IMPROVEMENT | 50-69 | Below expectations |
| NON_COMPLIANT | 0-49 | Serious compliance issues |

---

### 8.2.5 penalty_rules
Penalty rules for violations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `code` | VARCHAR(30) | UNIQUE, NOT NULL | Rule code |
| `name_en` | VARCHAR(100) | NOT NULL | English name |
| `name_bn` | VARCHAR(100) | | Bengali name |
| `description` | TEXT | | Rule description |
| `qos_parameter_id` | INTEGER | FK → qos_parameters.id | Related parameter (optional) |
| `violation_severity` | VARCHAR(20) | | Applicable severity |
| `occurrence_threshold` | INTEGER | DEFAULT 1 | Violations before penalty |
| `penalty_type` | VARCHAR(20) | NOT NULL | FIXED/PERCENTAGE/TIERED |
| `base_penalty_bdt` | DECIMAL(15,2) | | Base penalty amount |
| `penalty_percentage` | DECIMAL(5,2) | | Percentage of revenue |
| `penalty_tiers` | JSONB | | Tiered penalty structure |
| `max_penalty_bdt` | DECIMAL(15,2) | | Maximum penalty cap |
| `grace_period_days` | INTEGER | DEFAULT 0 | Grace period |
| `escalation_multiplier` | DECIMAL(3,2) | DEFAULT 1.00 | Repeat offense multiplier |
| `btrc_regulation_ref` | VARCHAR(100) | | Regulation reference |
| `effective_date` | DATE | NOT NULL | When effective |
| `expiry_date` | DATE | | Expiration date |
| `is_active` | BOOLEAN | DEFAULT true | Active status |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator |

---

## 8.3 Compliance Score Calculation

```sql
-- Monthly compliance score calculation
WITH violation_summary AS (
    SELECT
        isp_id,
        DATE_TRUNC('month', detection_time) AS month,
        COUNT(*) AS total_violations,
        COUNT(*) FILTER (WHERE severity = 'CRITICAL') AS critical_count,
        COUNT(*) FILTER (WHERE severity = 'HIGH') AS high_count,
        COUNT(*) FILTER (WHERE severity = 'MEDIUM') AS medium_count,
        COUNT(*) FILTER (WHERE severity = 'LOW') AS low_count,
        COUNT(*) FILTER (WHERE status = 'RESOLVED') AS resolved_count,
        AVG(EXTRACT(EPOCH FROM (resolved_at - detection_time))/3600)
            FILTER (WHERE resolved_at IS NOT NULL) AS avg_resolution_hours
    FROM sla_violations
    WHERE detection_time >= DATE_TRUNC('month', :target_month)
        AND detection_time < DATE_TRUNC('month', :target_month) + INTERVAL '1 month'
    GROUP BY isp_id, DATE_TRUNC('month', detection_time)
),
score_calc AS (
    SELECT
        vs.isp_id,
        vs.month,
        -- Base score of 100, deduct for violations
        GREATEST(0, 100
            - (vs.critical_count * 15)
            - (vs.high_count * 10)
            - (vs.medium_count * 5)
            - (vs.low_count * 2)
            + (vs.resolved_count * 2)  -- Bonus for resolution
        ) AS overall_score,
        vs.*
    FROM violation_summary vs
)
INSERT INTO compliance_scores (
    isp_id, score_month, overall_score, total_violations,
    critical_violations, high_violations, medium_violations, low_violations,
    resolved_violations, avg_resolution_hours
)
SELECT
    isp_id, month, overall_score, total_violations,
    critical_count, high_count, medium_count, low_count,
    resolved_count, avg_resolution_hours
FROM score_calc;
```

---

## 8.4 Entity Relationship Summary

```
qos_parameters
    └── sla_thresholds
            ├── isp_license_categories
            └── package_types

sla_violations
    ├── isps
    ├── pops
    ├── qos_parameters
    ├── sla_thresholds
    └── penalty_rules

compliance_scores
    └── isps (monthly)

penalty_rules
    └── qos_parameters
```

---

## 8.5 Data Retention Policies

```sql
-- Detailed violations: 1 year
-- Note: Implement via application logic or scheduled job

-- Compliance scores: Keep indefinitely (aggregated data)
-- Archive old violations to cold storage after 1 year
```

---

## 8.6 Table Count Summary

| Table | Expected Records | Growth Rate |
|-------|------------------|-------------|
| qos_parameters | ~20 | Static |
| sla_thresholds | ~200 | Low |
| sla_violations | ~100,000/year | High |
| compliance_scores | ~18,000/year | Medium |
| penalty_rules | ~50 | Low |

---

**End of Step 8 Documentation**
