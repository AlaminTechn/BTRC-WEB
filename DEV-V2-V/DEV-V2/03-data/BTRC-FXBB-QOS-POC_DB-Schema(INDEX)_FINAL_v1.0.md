# BTRC QoS Monitoring - Database Schema Design
## Master Index

| Metadata | Value |
|----------|-------|
| **Version** | 1.1 |
| **Created** | 2026-01-07 |
| **Updated** | 2026-01-12 |
| **PRD Reference** | 16-PRD-BTRC-QoS-MONITORING-v3.1.md |
| **API Alignment** | BTRC-FXBB-QOS-POC_Data-Model(INGESTION)_DRAFT_v0.8.md |
| **Database Stack** | PostgreSQL 15+ / TimescaleDB 2.x / Redis 7.x |
| **Total Steps** | 12 |

---

## Document Overview

This documentation describes the complete database schema for the BTRC Fixed Broadband QoS Monitoring System. The schema supports monitoring 1,500+ ISPs across Bangladesh with 5-source data collection architecture.

> **REVIEW NOTE (2026-01-17)**: PRD v3.1 defines 5-source collection architecture:
>
> | # | PRD Source Name | Schema Originator | POC Status |
> |---|-----------------|-------------------|------------|
> | 1 | SNMP-Collector-Agent | SNMP_AGENT | In Scope |
> | 2 | ISP API | ISP_API | In Scope |
> | 3 | QOS-Measurement-Agent | QOS_AGENT | In Scope |
> | 4 | Mobile-App (User-Facing) | USER_APP | In Scope |
> | 5 | Monitoring-tool (Field Officer) | REG_APP | End of POC |
>
> Schema supports all 5 sources. REG_APP (Monitoring-tool) is designed but deferred to end of POC phase for prioritization.

---

## Steps Summary Table

| Step | File | Status | Tables | Description |
|------|------|--------|--------|-------------|
| 1 | [Step01-Foundation](BTRC-FXBB-QOS-POC_DB-Schema(STEP-01-FOUNDATION)_FINAL_v1.0.md) | ✅ COMPLETED | 9 | Geographic hierarchy, ISP master data, License categories |
| 2 | [Step02-Infrastructure](BTRC-FXBB-QOS-POC_DB-Schema(STEP-02-INFRASTRUCTURE)_FINAL_v1.0.md) | ✅ COMPLETED | 10 | PoPs, Software agents, SNMP targets, Test targets |
| 3 | [Step03-ProductSubscriber](BTRC-FXBB-QOS-POC_DB-Schema(STEP-03-PRODUCT-SUBSCRIBER)_FINAL_v1.0.md) | ✅ COMPLETED | 7 | Packages, Tariffs, Subscriber snapshots |
| 4 | [Step04-TimeSeries](BTRC-FXBB-QOS-POC_DB-Schema(STEP-04-TIMESERIES)_FINAL_v1.0.md) | ✅ COMPLETED | 3+CA | TimescaleDB hypertables, Continuous aggregates |
| 5 | [Step05-MobileApp](BTRC-FXBB-QOS-POC_DB-Schema(STEP-05-MOBILE-APP)_FINAL_v1.0.md) | ✅ COMPLETED | 8 | App installations, Mobile speed tests, Field reports |
| 6 | [Step06-Operational](BTRC-FXBB-QOS-POC_DB-Schema(STEP-06-OPERATIONAL)_FINAL_v1.0.md) | ✅ COMPLETED | 7 | Incidents, Outages, Complaint aggregates, MTTR |
| 7 | [Step07-RevenueAnalytics](BTRC-FXBB-QOS-POC_DB-Schema(STEP-07-REVENUE-ANALYTICS)_FINAL_v1.0.md) | ✅ COMPLETED | 4 | Revenue snapshots, Revenue details, Package analytics, Market analytics |
| 8 | [Step08-ComplianceSLA](BTRC-FXBB-QOS-POC_DB-Schema(STEP-08-COMPLIANCE-SLA)_FINAL_v1.0.md) | ✅ COMPLETED | 5 | QoS parameters, SLA thresholds, Violations, Compliance scores |
| 9 | [Step09-UserSecurity](BTRC-FXBB-QOS-POC_DB-Schema(STEP-09-USER-SECURITY)_FINAL_v1.0.md) | ✅ COMPLETED | 8 | Users, RBAC, Sessions, API keys, Audit logs |
| 10 | [Step10-IntegrationAPI](BTRC-FXBB-QOS-POC_DB-Schema(STEP-10-INTEGRATION-API)_FINAL_v1.0.md) | ✅ COMPLETED | 9 | API submissions, Data provenance, Discrepancy detection |
| 11 | [Step11-SystemObservability](BTRC-FXBB-QOS-POC_DB-Schema(STEP-11-SYSTEM-OBSERVABILITY)_FINAL_v1.0.md) | ✅ COMPLETED | 10 | Alerts, Notifications, System health, Dashboard cache |
| 12 | [Step12-SchemaOptimization](BTRC-FXBB-QOS-POC_DB-Schema(STEP-12-SCHEMA-OPTIMIZATION)_FINAL_v1.0.md) | ✅ COMPLETED | 1+~146 idx | Indexes, Partitioning, Performance tuning |

---

## Key Design Decisions (Global)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Primary Database** | PostgreSQL 15+ | Mature, extensible, JSON support |
| **Time-Series Extension** | TimescaleDB 2.x | Native PostgreSQL, hypertables, continuous aggregates |
| **Caching Layer** | Redis 7.x | Session management, real-time dashboards |
| **Schema Separation** | ⏳ **DEFERRED** | POC uses `public`; Production uses `raw`/`aggr`/`app` schemas. See [Tech-Spec(STACK-PLAN)](../01-planning/BTRC-FXBB-QOS-POC_Tech-Spec(STACK-PLAN)_DRAFT_v0.2.md) for migration strategy |
| **Audit Columns** | Yes | `created_at`, `updated_at`, `created_by`, `updated_by` |
| **Soft Delete** | Yes | `deleted_at` column for recoverable deletion |
| **Multi-tenancy** | Yes | ISP-scoped access via `isp_id` foreign keys |

---

## Data Originators

| Originator | Description | Trust Level | Full Payload | Dedup Window |
|------------|-------------|-------------|--------------|--------------|
| SNMP_AGENT | SNMP Docker agent | 95 | Metadata | 24 hours |
| QOS_AGENT | QoS Docker agent | 90 | Metadata | 24 hours |
| ISP_API | ISP-submitted data | 70 | Full | Monthly |
| MANUAL | Manual data entry | 60 | Metadata | None |
| CALCULATED | Platform-calculated | N/A | N/A | N/A |

---
