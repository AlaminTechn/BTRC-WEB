# 01-planning

Sprint planning, task lists, and architectural decisions.

## Purpose

Define WHAT needs to be done and WHY. Planning documents feed into tracking.

## Allowed Section Keywords

| Keyword | Purpose |
|---------|---------|
| `Dev-Plan` | Development plans, task lists, sprint plans |
| `Dev-Spec` | Development specifications |
| `Tech-Spec` | Technology specifications, stack decisions |
| `ADR` | Architecture Decision Records |

## Naming Examples

- `BTRC-FXBB-QOS-POC_Dev-Plan(POC-TASK-LIST)_DRAFT_v0.3.md`
- `BTRC-FXBB-QOS-POC_Dev-Plan(SPRINT-1)_FINAL_v1.0.md`
- `BTRC-FXBB-QOS-POC_Tech-Spec(STACK-PLAN)_FINAL_v1.0.md`
- `BTRC-FXBB-QOS-POC_ADR(DATABASE-CHOICE)_FINAL_v1.0.md`

## Relationship to Tracking

| This Folder | Feeds Into |
|-------------|------------|
| Dev-Plan (task list) | Sprint Tracker tasks |
| Dev-Plan (sprint plan) | Sprint Tracker goals |
| ADR | Milestone success criteria |

## Rules

- Use Denominator from registry (see DEV/CLAUDE.md)
- Major version bump (v0.9 → v1.0) archives previous version
- Single digit after decimal only
- ADRs should be FINAL once decision is made
