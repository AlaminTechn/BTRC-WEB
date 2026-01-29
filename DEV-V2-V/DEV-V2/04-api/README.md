# 04-api

API specifications, contracts, and service development guides.

## Purpose

Define API interfaces and service specifications. Guide for implementation.

## Allowed Section Keywords

| Keyword | Purpose |
|---------|---------|
| `API-Spec` | REST/GraphQL API specifications |
| `API-Contract` | Interface contracts between services |
| `Dev-Spec` | Development specifications for services/agents |

## Naming Examples

- `BTRC-FXBB-QOS-POC_API-Spec(REST-ENDPOINTS)_DRAFT_v0.3.md`
- `BTRC-FXBB-QOS-POC_API-Contract(ISP-SUBMISSION)_FINAL_v1.0.md`
- `BTRC-FXBB-QOS-POC_Dev-Spec(API-SERVER)_REVIEW-PENDING_v0.9.md`
- `BTRC-FXBB-QOS-POC_Dev-Spec(SNMP-AGENT)_FINAL_v1.0.md`

## Relationship to Tracking

| This Folder | Feeds Into |
|-------------|------------|
| API-Spec | Sprint tasks, Milestone criteria |
| Dev-Spec | Implementation guide |
| API-Contract | Integration testing |

## Rules

- Use Denominator from registry (see DEV/CLAUDE.md)
- Major version bump (v0.9 → v1.0) archives previous version
- Single digit after decimal only
- Keep API-Spec and Dev-Spec versions aligned
