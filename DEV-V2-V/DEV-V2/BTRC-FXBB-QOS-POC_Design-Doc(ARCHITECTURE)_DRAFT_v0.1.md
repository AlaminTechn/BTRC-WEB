# POC Architecture Overview - BTRC QoS Monitoring System

| Metadata | Value |
|----------|-------|
| **Document** | POC Architecture Diagram |
| **Version** | 0.1 (Initial Draft) |
| **Status** | DRAFT |
| **Created** | 2026-01-19 |
| **Updated** | 2026-01-19 |
| **Author** | Technometrics |
| **Project** | BTRC Fixed Broadband QoS Monitoring System |

---

## 1. Architecture Overview

The BTRC Fixed Broadband QoS Monitoring System POC consists of three main layers:

| Layer | Component | Description |
|-------|-----------|-------------|
| **Presentation** | Frontend | Dashboard UI for Executive, Tech-Ops, and Regulatory users |
| **Application** | Backend API | REST API serving processed data to frontend |
| **Data** | Data Ingestion | Receives, validates, transforms, and stores telemetry data |

---

## 2. High-Level Architecture Diagram

```mermaid
flowchart TB
    subgraph DataSources["Data Sources (ISP Premises)"]
        SNMP["SNMP_AGENT<br/>Docker Container"]
        QOS["QOS_AGENT<br/>Docker Container"]
        ISP["ISP Portal<br/>Self-Reported Data"]
    end

    subgraph DataIngestion["Data Ingestion Layer"]
        subgraph Channels["Channel Receivers"]
            SNMP_CH["SNMP Channel<br/>/api/v1/submissions/snmp-combined"]
            QOS_CH["QOS Channel<br/>/api/v1/submissions/qos-measurements"]
            ISP_CH["ISP-API Channel<br/>/api/v1/isp-data/*"]
        end

        subgraph Processing["Processing Pipeline"]
            VAL["Validation Engine<br/>Schema & Bounds Check"]
            DEDUP["Deduplication<br/>UUID & Provenance"]
            TRANS["Transformation<br/>Rate Calculation & Normalization"]
            AGG["Aggregation<br/>15min → Hourly → Daily"]
        end
    end

    subgraph Storage["Data Storage"]
        TSDB[("TimescaleDB<br/>Time-Series Data")]
        PG[("PostgreSQL<br/>Config & Master Data")]
    end

    subgraph Backend["Backend API Layer"]
        API["API Server<br/>REST/JSON"]
        AUTH["Authentication<br/>API Key + JWT"]
        QUERY["Query Service<br/>Aggregated Data Access"]
    end

    subgraph Frontend["Frontend Layer"]
        subgraph Dashboards["Dashboard Applications"]
            EXEC["Executive Dashboard<br/>High-Level KPIs"]
            TECH["Tech-Ops Dashboard<br/>Operational Metrics"]
            REG["Regulatory Dashboard<br/>Compliance Reports"]
        end
    end

    %% Data Flow: Sources to Ingestion
    SNMP -->|"Every 15 min<br/>Trust: 95"| SNMP_CH
    QOS -->|"Every 15 min<br/>Trust: 90"| QOS_CH
    ISP -->|"Daily/Monthly<br/>Trust: 70"| ISP_CH

    %% Data Flow: Ingestion Processing
    SNMP_CH --> VAL
    QOS_CH --> VAL
    ISP_CH --> VAL
    VAL --> DEDUP
    DEDUP --> TRANS
    TRANS --> AGG

    %% Data Flow: To Storage
    TRANS --> TSDB
    AGG --> TSDB

    %% Backend connections
    API --> AUTH
    API --> QUERY
    QUERY --> TSDB
    QUERY --> PG

    %% Frontend connections
    EXEC --> API
    TECH --> API
    REG --> API
```

---

## 3. Component Architecture Diagram

```mermaid
flowchart LR
    subgraph Agents["Distributed Agents"]
        direction TB
        A1["SNMP_AGENT"]
        A2["QOS_AGENT"]
        A3["ISP_API"]
    end

    subgraph Core["Core Platform"]
        direction TB
        subgraph Ingest["Data Ingestion"]
            I1["Receive & Auth"]
            I2["Validate"]
            I3["Transform"]
            I4["Store"]
        end

        subgraph Process["Processing"]
            P1["Aggregation"]
        end

        subgraph Serve["Backend API"]
            S1["Query API"]
            S2["Dashboard API"]
            S3["Admin API"]
        end
    end

    subgraph DB["Databases"]
        D1[("TimescaleDB")]
        D2[("PostgreSQL")]
    end

    subgraph UI["Frontend"]
        U1["Executive"]
        U2["Tech-Ops"]
        U3["Regulatory"]
    end

    A1 --> I1
    A2 --> I1
    A3 --> I1

    I1 --> I2 --> I3 --> I4
    I4 --> D1
    I4 --> D2

    I4 --> P1
    P1 --> D1

    D1 --> S1
    D2 --> S1

    S1 --> S2
    S2 --> U1
    S2 --> U2
    S2 --> U3
```

---

## 4. Data Flow Diagram

```mermaid
sequenceDiagram
    participant SNMP as SNMP_AGENT
    participant QOS as QOS_AGENT
    participant ISP as ISP Portal
    participant ING as Data Ingestion
    participant PROC as Processing
    participant DB as TimescaleDB
    participant API as Backend API
    participant FE as Frontend

    Note over SNMP,ISP: Data Collection Phase

    SNMP->>ING: POST /snmp-combined (every 15 min)
    QOS->>ING: POST /qos-measurements (every 15 min)
    ISP->>ING: POST /isp-data/* (daily/monthly)

    Note over ING,PROC: Data Processing Phase

    ING->>ING: Validate Schema & Bounds
    ING->>ING: Deduplicate (UUID check)
    ING->>ING: Transform & Normalize
    ING->>DB: Store Raw Metrics

    ING->>PROC: Trigger Processing
    PROC->>DB: Store Aggregates (15min→hourly→daily)

    Note over API,FE: Data Presentation Phase

    FE->>API: Request Dashboard Data
    API->>DB: Query Aggregated Metrics
    DB-->>API: Return Results
    API-->>FE: JSON Response
    FE->>FE: Render Visualizations
```

---

## 5. Deployment Architecture

```mermaid
flowchart TB
    subgraph ISP_Site["ISP Premises (5 Demo ISPs)"]
        subgraph Docker1["Docker Host"]
            SNMP_C["SNMP_AGENT Container"]
            QOS_C["QOS_AGENT Container"]
        end
        ROUTER["Network Devices<br/>SNMP-enabled"]
    end

    subgraph BTRC_DC["BTRC Data Center"]
        subgraph AppTier["Application Tier"]
            API_SRV["API_SERVER"]
            PROC_C["PROCESSING<br/>Container"]
        end

        subgraph DataTier["Data Tier"]
            TS_PRIMARY[("TimescaleDB<br/>Primary")]
            PG_PRIMARY[("PostgreSQL<br/>Primary")]
        end

        subgraph WebTier["Web Tier"]
            WEB["Frontend<br/>Static Assets"]
        end
    end

    subgraph Users["Users"]
        EXEC_USER["Executive Users"]
        TECH_USER["Tech-Ops Users"]
        REG_USER["Regulatory Users"]
    end

    ROUTER -.->|SNMP| SNMP_C
    SNMP_C -->|HTTPS| API_SRV
    QOS_C -->|HTTPS| API_SRV

    API_SRV --> TS_PRIMARY
    API_SRV --> PG_PRIMARY

    PROC_C --> TS_PRIMARY
    PROC_C --> PG_PRIMARY

    EXEC_USER --> WEB
    TECH_USER --> WEB
    REG_USER --> WEB
```

---

## 6. Component Summary

| Component | Technology | Purpose |
|-----------|------------|---------|
| **SNMP_AGENT** | Python/Docker | Collects interface metrics & subscriber counts from ISP devices |
| **QOS_AGENT** | Python/Docker | Performs speed, latency, DNS, HTTP tests |
| **ISP Portal** | Web Interface | ISP self-reported data (packages, subscribers, revenue) |
| **Data Ingestion** | Python/FastAPI | Receives, validates, deduplicates, transforms incoming data |
| **Processing** | Python | Data aggregation (15min → hourly → daily rollups) |
| **Backend API** | Python/FastAPI | REST API for dashboard data queries |
| **Frontend** | React/TypeScript | Dashboard UIs for different user roles |
| **TimescaleDB** | PostgreSQL + TimescaleDB | Time-series metric storage with hypertables |
| **PostgreSQL** | PostgreSQL 15+ | Configuration and master data |

---

## 7. Data Trust Levels

| Source | Trust Level | Validation | Frequency |
|--------|-------------|------------|-----------|
| SNMP_AGENT | 95 | Agent-signed, schema-validated | Every 15 min |
| QOS_AGENT | 90 | Agent-signed, schema-validated | Every 15 min |
| ISP_API | 70 | ISP-authenticated, cross-validated | Daily/Monthly |

---

## Related Documents

| Document | Description |
|----------|-------------|
| [Dev-Spec(API-SERVER)](../knowledge_base/04-api/BTRC-FXBB-QOS-POC_Dev-Spec(API-SERVER)_REVIEW-PENDING_v0.9.md) | API Server specifications |
| [Dev-Spec(SNMP-AGENT)](../knowledge_base/04-api/BTRC-FXBB-QOS-POC_Dev-Spec(SNMP-AGENT)_REVIEW-PENDING_v0.9.md) | SNMP Agent specifications |
| [Dev-Spec(QOS-AGENT)](../knowledge_base/04-api/BTRC-FXBB-QOS-POC_Dev-Spec(QOS-AGENT)_REVIEW-PENDING_v0.9.md) | QOS Agent specifications |
| [DB-Schema(INDEX)](../knowledge_base/03-data/BTRC-FXBB-QOS-POC_DB-Schema(INDEX)_FINAL_v1.0.md) | Database schema reference |
| [Design-Doc(DASHBOARD-EXECUTIVE)](../knowledge_base/05-ui/BTRC-FXBB-QOS-POC_Design-Doc(DASHBOARD-EXECUTIVE)_FINAL_v1.0.md) | Executive Dashboard design |
