# BTRC QoS Monitoring - Database Schema Design
## Step 7: Revenue & Analytics

| Metadata | Value |
|----------|-------|
| **Version** | 1.1 |
| **Status** | COMPLETED |
| **Created** | 2026-01-07 |
| **Updated** | 2026-01-12 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **Database** | PostgreSQL + TimescaleDB |

---

## 7.1 Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Revenue Data Access | Strict RBAC | Revenue is sensitive; scoped role access only |
| ARPU Calculation | Platform calculates | Calculated from revenue/subscriber snapshots |
| Market Analytics | On-demand queries | No pre-computed tables; query when needed |

> **📋 Review Note**: Consider implementing batch job for market analytics if on-demand queries become too slow with large datasets. Evaluate after 6 months of operation.

---

## 7.2 Table Definitions

### 7.2.1 revenue_snapshots
Monthly revenue data from ISPs (RBAC protected).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | ISP |
| `snapshot_month` | DATE | NOT NULL | Month (first day) |
| `gross_revenue_bdt` | DECIMAL(15,2) | | Gross revenue in BDT |
| `net_revenue_bdt` | DECIMAL(15,2) | | Net revenue in BDT |
| `subscription_revenue_bdt` | DECIMAL(15,2) | | Subscription revenue |
| `installation_revenue_bdt` | DECIMAL(15,2) | | Installation fees |
| `other_revenue_bdt` | DECIMAL(15,2) | | Other revenue |
| `vat_bdt` | DECIMAL(15,2) | | VAT collected |
| `total_subscribers` | INTEGER | | Total subscribers this month |
| `paying_subscribers` | INTEGER | | Paying subscribers |
| `arpu_bdt` | DECIMAL(10,2) | | Calculated ARPU |
| `revenue_per_mbps_bdt` | DECIMAL(10,2) | | Revenue per Mbps sold |
| `data_source` | VARCHAR(20) | DEFAULT 'ISP_API' | ISP_API/MANUAL/CALCULATED |
| `submission_id` | INTEGER | FK → api_submissions.id | Source submission |
| `is_verified` | BOOLEAN | DEFAULT false | BTRC verified |
| `verified_by` | INTEGER | FK → users.id | Verifier |
| `verified_at` | TIMESTAMPTZ | | Verification timestamp |
| `verification_notes` | TEXT | | Verification notes |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |
| `created_by` | INTEGER | FK → users.id | Creator |
| `updated_by` | INTEGER | FK → users.id | Last updater |

**Index**: `UNIQUE(isp_id, snapshot_month)`

**RBAC Note**: This table requires `revenue:read` permission. Only specific roles (Finance, Executive) should have access.

---

### 7.2.2 revenue_details
Granular revenue data by Package × Location (from ISP API submissions).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `isp_id` | INTEGER | FK → isps.id, NOT NULL | ISP |
| `snapshot_month` | DATE | NOT NULL | Month (first day) |
| `package_id` | INTEGER | FK → packages.id | Package |
| `geo_id` | VARCHAR(20) | | Location identifier |
| `subscriber_revenue_bdt` | DECIMAL(15,2) | | Net revenue from subscribers |
| `vat_bdt` | DECIMAL(15,2) | | VAT collected |
| `submission_id` | INTEGER | FK → api_submissions.id | Source submission |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(isp_id, snapshot_month, package_id, geo_id)`

**RBAC Note**: Same access restrictions as revenue_snapshots.

> **📋 Review Note**: Revenue verification logic location TBD (app layer, triggers, or batch job). Decision deferred for future implementation phase.

---

### 7.2.3 package_analytics
Package-level performance analytics (calculated by platform).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `package_id` | INTEGER | FK → packages.id, NOT NULL | Package |
| `analytics_month` | DATE | NOT NULL | Month (first day) |
| `subscriber_count` | INTEGER | | Subscribers on this package |
| `new_subscribers` | INTEGER | | New subscribers |
| `churned_subscribers` | INTEGER | | Churned subscribers |
| `churn_rate_pct` | DECIMAL(5,2) | | Churn rate percentage |
| `revenue_bdt` | DECIMAL(15,2) | | Revenue from this package |
| `arpu_bdt` | DECIMAL(10,2) | | Package ARPU |
| `avg_actual_download_mbps` | DECIMAL(10,2) | | Measured avg download |
| `avg_actual_upload_mbps` | DECIMAL(10,2) | | Measured avg upload |
| `speed_achievement_pct` | DECIMAL(5,2) | | % of advertised speed achieved |
| `avg_latency_ms` | DECIMAL(10,2) | | Average latency |
| `complaint_count` | INTEGER | | Complaints for this package |
| `satisfaction_score` | DECIMAL(3,2) | | Satisfaction score (1-5) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | | Last update timestamp |

**Index**: `UNIQUE(package_id, analytics_month)`

---

### 7.2.4 market_analytics
Market-level analytics (on-demand calculation, optional caching).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PK | Auto-increment ID |
| `analytics_month` | DATE | NOT NULL | Month (first day) |
| `district_id` | INTEGER | FK → geo_districts.id | Geographic scope (optional) |
| `license_category_id` | INTEGER | FK → isp_license_categories.id | ISP category (optional) |
| `total_isps` | INTEGER | | ISPs in scope |
| `total_subscribers` | INTEGER | | Total subscribers |
| `total_bandwidth_gbps` | DECIMAL(12,2) | | Total bandwidth |
| `market_revenue_bdt` | DECIMAL(18,2) | | Total market revenue |
| `avg_arpu_bdt` | DECIMAL(10,2) | | Market average ARPU |
| `avg_download_mbps` | DECIMAL(10,2) | | Market avg download |
| `avg_upload_mbps` | DECIMAL(10,2) | | Market avg upload |
| `avg_latency_ms` | DECIMAL(10,2) | | Market avg latency |
| `hhi_index` | DECIMAL(8,4) | | Herfindahl-Hirschman Index |
| `top_5_market_share_pct` | DECIMAL(5,2) | | Top 5 ISPs market share |
| `yoy_subscriber_growth_pct` | DECIMAL(6,2) | | Year-over-year growth |
| `yoy_revenue_growth_pct` | DECIMAL(6,2) | | Revenue growth |
| `calculation_time` | TIMESTAMPTZ | DEFAULT NOW() | When calculated |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Index**: `UNIQUE(analytics_month, district_id, license_category_id)`

**Note**: This table is optional for caching. Primary approach is on-demand query aggregation.

---

## 7.3 ARPU Calculation Logic

The platform calculates ARPU from revenue and subscriber snapshots:

```sql
-- Monthly ARPU calculation
UPDATE revenue_snapshots rs
SET arpu_bdt = CASE
    WHEN rs.paying_subscribers > 0
    THEN rs.net_revenue_bdt / rs.paying_subscribers
    ELSE NULL
END
WHERE rs.snapshot_month = :target_month
    AND rs.arpu_bdt IS NULL;

-- Alternative: Calculate during insertion
INSERT INTO revenue_snapshots (
    isp_id, snapshot_month, gross_revenue_bdt, net_revenue_bdt,
    total_subscribers, paying_subscribers, arpu_bdt
)
SELECT
    :isp_id,
    :month,
    :gross_revenue,
    :net_revenue,
    :total_subs,
    :paying_subs,
    CASE WHEN :paying_subs > 0
        THEN :net_revenue / :paying_subs
        ELSE NULL
    END;
```

---

## 7.4 On-Demand Market Analytics Query

```sql
-- Market overview for a specific month
SELECT
    DATE_TRUNC('month', :target_month) AS analytics_month,
    COUNT(DISTINCT i.id) AS total_isps,
    SUM(ss.total_subscribers) AS total_subscribers,
    SUM(bs.total_international_gbps + bs.total_bdix_gbps) AS total_bandwidth_gbps,
    SUM(rs.net_revenue_bdt) AS market_revenue_bdt,
    AVG(rs.arpu_bdt) AS avg_arpu_bdt,
    -- HHI calculation
    SUM(POWER(ss.total_subscribers::DECIMAL /
        NULLIF((SELECT SUM(total_subscribers) FROM subscriber_snapshots
                WHERE snapshot_month = :target_month), 0) * 100, 2)) AS hhi_index
FROM isps i
LEFT JOIN subscriber_snapshots ss ON ss.isp_id = i.id AND ss.snapshot_month = :target_month
LEFT JOIN bandwidth_snapshots bs ON bs.isp_id = i.id AND bs.snapshot_month = :target_month
LEFT JOIN revenue_snapshots rs ON rs.isp_id = i.id AND rs.snapshot_month = :target_month
WHERE i.is_active = true;
```

---

## 7.5 Entity Relationship Summary

```
isps
    ├── revenue_snapshots (RBAC protected)
    ├── revenue_details (RBAC protected)
    │       └── packages (FK)
    └── packages
            └── package_analytics

market_analytics (cached/on-demand)
    ├── geo_districts (optional scope)
    └── isp_license_categories (optional scope)
```

---

## 7.6 RBAC Configuration

| Role | revenue_snapshots | revenue_details | package_analytics | market_analytics |
|------|-------------------|-----------------|-------------------|------------------|
| BTRC_ADMIN | Full Access | Full Access | Full Access | Full Access |
| BTRC_FINANCE | Full Access | Full Access | Read | Full Access |
| BTRC_ANALYST | Read (anonymized) | Read (anonymized) | Read | Read |
| BTRC_OPERATOR | No Access | No Access | Read | Read |
| ISP_ADMIN | Own ISP Only | Own ISP Only | Own ISP Only | No Access |
| ISP_USER | No Access | No Access | Own ISP Only | No Access |

---

## 7.7 Table Count Summary

| Table | Expected Records | Growth Rate |
|-------|------------------|-------------|
| revenue_snapshots | ~18,000/year | Medium |
| revenue_details | ~200,000/year | Medium |
| package_analytics | ~180,000/year | Medium |
| market_analytics | ~1,000/year | Low (if cached) |

---

**End of Step 7 Documentation**
