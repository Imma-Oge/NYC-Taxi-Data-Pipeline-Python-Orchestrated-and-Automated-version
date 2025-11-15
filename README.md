# NYC-Taxi-Data-Pipeline-Python-Orchestrated-and-Automated-version

This project upgrades a simple NYC_Taxi_2024-ELT workflow into a production-grade, automated, Python-orchestrated pipeline.
It demonstrates:
* Full Load and Incremental Load strategies
* Bronze → Silver → Gold ELT architecture
* Snowflake streams + tasks for incremental metadata
* Python orchestration using the Snowflake Connector
* Centralized metadata management
* Retry + error handling + logging
* Automated testing (pytest) & linting (flake8)
* CI/CD with GitHub Actions + branch protection rules

## Layer Purpose (Full Load vs Incremental Load)
The pipeline uses a multi-layer ELT architecture across Bronze, Silver, and Gold schemas.
Each layer has its own responsibility, whether the pipeline is running a full refresh or an incremental update.

### * Bronze Layer — Raw Ingestion Layer
#### Purpose
* Acts as the landing zone for raw data (full or streaming incremental load).
* Holds data exactly as received, with minimal transformations.
* Serves as the source of truth for downstream processing.
* 
#### Full Load Behavior
* Raw files are ingested from the internal stage via Snowflake COPY INTO
* All 12 datasets are loaded from the stage

#### Incremental Load Behavior
* Snowflake Streams track new/changed records on the raw table since last run
* Only new or changed records are ingested
* No truncation involved

### * Silver Layer — Clean, Standardized Layer
#### Purpose
* Applies data quality checks, transformations, mapping and data enrichment.
* Standardizes fields into analytics-friendly formats.

#### Full Load Behavior
* Silver layer table is rebuilt by transforming the Bronze layer data
* Executed as a full load using INSERT INTO SELECT syntax.

#### Incremental Load Behavior
Uses Raw stream metadata to update only new rows
Upsert logic: 

```
MERGE INTO silver.transform AS t
USING raw_stream AS s
ON t.id = s.id
WHEN MATCHED THEN UPDATE ...
WHEN NOT MATCHED THEN INSERT ...

```

### * Gold Layer — Aggregation & Business Logic Layer
#### Purpose
* Produces final analytical outputs, aggregated measures, and KPI datasets.
* Serves BI tools, dashboards, and downstream apps.

### Data flows through the pipeline via:

* Full Load Path: Stage → Bronze → Silver → Gold
* Incremental Path: Stage → raw_stream → Silver MERGE → Gold refresh
* All transformations occur inside Snowflake using SQL, while Python orchestrates the execution sequence.

### Role of Orchestration & Metadata Management
#### Python Orchestration
The entire ELT pipeline is automated with Python (using the Snowflake Connector).
The orchestrator handles:
* Executing SQL files in the correct order
* Passing parameters (load type, date ranges)
* Handling retries and capturing errors
* Updating metadata and logs
* Triggering full or incremental load workflows
* Scheduling (via cron in GitHub Actions)
  
Orchestration ensures the pipeline is modular, automated, and production-ready.

### Metadata Management.
A dedicated metadata table is used to track:
| Column   | Description 
|----------|----------
| last_successful_load  | Timestamp of last pipeline success
| run_status            | SUCCESS or FAILED
| load_type             | FULL or INCREMENTAL
| error_message         | Logged error message

The orchestrator reads metadata to decide which load strategy to run and updates metadata after each run.
```
INSERT INTO metadata.pipeline_runs 
(run_status, load_type, last_successful_load)
VALUES ('SUCCESS', 'INCREMENTAL', CURRENT_TIMESTAMP);
```
This enables:
* Restartability
* Failure tracking
* Operational observability
* Easy debugging

### Retry & Logging Strategy
#### Logging Design
Logging uses Python's built-in logging module.
Each log entry contains:
* Timestamp
* Log level (INFO, WARNING, ERROR)
* Message
* SQL script name or job step
  Example log format:

Logs help track:
* Execution progress
* Errors in SQL scripts
* Performance issues
* Pipeline health

Logs are written to:
pipeline.log file in VS Code

#### Retry Logic

### CI/CD Workflow & Branch Protection Design

#### CI/CD Workflow & Deployment Pipeline
This project implements a comprehensive CI/CD strategy using GitHub Actions with separate workflows for continuous integration, infrastructure deployment, and pipeline execution across development and production environments.
Workflow Architecture
The CI/CD pipeline follows a branch-based deployment model with automated testing, infrastructure provisioning, and scheduled production runs.

```
┌─────────────────────────────────────┐
│  Work on ogee_dev branch            │
│  (Development Environment)          │
└──────────────┬──────────────────────┘
               │
               ▼
     ┌─────────────────────┐
     │ Push to ogee_dev    │
     └─────────┬───────────┘
               │
               ├─────────────────┬──────────────────┐
               │                 │                  │
               ▼                 ▼                  ▼
        ┌──────────┐      ┌────────────┐    ┌─────────────┐
        │ ci.yml   │      │cd_infra_   │    │cd_pipeline_ │
        │ runs     │      │dev.yml     │    │dev.yml      │
        │ (tests)  │      │(if infra   │    │(if pipeline │
        └──────────┘      │changed)    │    │changed)     │
                          └────────────┘    └─────────────┘
               │
               ▼
     ┌─────────────────────┐
     │ Create Pull Request │
     │   to main           │
     └─────────┬───────────┘
               │
               ▼
     ┌─────────────────────┐
     │ ci.yml runs on PR   │
     │ (validates code)    │
     └─────────┬───────────┘
               │
               ▼
     ┌─────────────────────┐
     │ Merge to main       │
     │ (Production Deploy) │
     └─────────┬───────────┘
               │
               ├─────────────────┬──────────────────┐
               │                 │                  │
               ▼                 ▼                  ▼
        ┌──────────┐      ┌────────────┐    ┌─────────────┐
        │ CI passes│      │cd_infra_   │    │cd_pipeline_ │
        │          │      │prod.yml    │    │prod.yml     │
        │          │      │(if infra   │    │(if pipeline │
        │          │      │changed)    │    │changed)     │
        └──────────┘      └────────────┘    └──────┬──────┘
                                                    │
                                                    ├─────────────────┐
                                                    │                 │
                                              On merge        Scheduled run
                                                              (Daily 2 AM UTC)
```

Workflow Components:


* Continuous Integration (ci.yml)
#### Triggers:
    
Every push to ogee_dev
Pull requests to main

#### Actions:
Runs pytest for unit and integration tests
Executes flake8 linting for code quality
Validates dependencies installation
Blocks Pull Request merge if tests fail

#### Purpose: Ensures code quality and prevents broken code from reaching production.


* Infrastructure Deployment - Dev (cd_infra_dev.yml)
#### Triggers:
Push to ogee_dev (only when files in infra/snowflake/** or full_load/ddl.sql change)

#### Actions:

Connects to Snowflake dev environment
Executes DDL scripts to create/update:
* Databases
* Schemas
* Tables

#### Purpose: Automatically provisions and updates database infrastructure in the dev environment.


* Infrastructure Deployment - Prod (cd_infra_prod.yml)
#### Triggers:
Merge to main (only when infrastructure files change)

#### Actions:
Deploys infrastructure changes to production Snowflake environment
Uses production credentials and warehouse
Optional: Requires manual approval before deployment

#### Purpose: Maintains production database structure with reviewed and tested changes.


* Pipeline Deployment - Dev (cd_pipeline_dev.yml)
#### Triggers:
Push to ogee_dev (when orchestration or SQL transformation files change)

#### Actions:
Runs the Python orchestration pipeline (orchestration/main.py)
Executes ELT workflows against dev databases
Uploads logs if pipeline fails

#### Purpose: Tests data pipeline logic in the dev environment before production deployment.

* Pipeline Deployment - Prod (cd_pipeline_prod.yml)
#### Triggers:
Merge to main (when pipeline code changes)
Scheduled: Daily at 2 AM UTC (cron: 0 2 * * *)
Manual trigger via GitHub UI (workflow_dispatch)

#### Actions:
Executes production ELT pipeline
Processes NYC taxi data through Bronze → Silver → Gold layers
Updates metadata tables
Captures and uploads logs on failure

#### Purpose: Runs production data processing workflows automatically and on schedule.

Environment Separation
| Environment | Branch | Databases              | Warehouse | Purpose |
|-------------|--------|----------------------- |-----------|----------
| Development |ogee_dev| FULL_LOAD, INCREMENTAL | DEV_WAREHOUSE| Testing and development
| Production  |main    |PROD_FULL_LOAD, PROD_INCREMENTAL| PROD_WAREHOUSE| Live data processing


 
#### Branch Protection Rules:
Applied to the main branch to ensure production stability:
Rule  |  Purpose|
|------|---------
|Require pull request before merging |Prevents direct pushes to main
|Require status checks to pass |CI must pass before merge
|Require code review approval |Peer review ensures quality
|Reject merge on CI failure |Guarantees pipeline integrity

Result: Code cannot reach production unless it passes all tests, linting, and receives approval.

Deployment Flow Summary

#### Development Phase:
* Work on ogee_dev branch
* Every push triggers CI tests
* Infrastructure and pipeline changes auto-deploy to dev environment
* Validate changes in dev before promoting to prod


#### Promotion to Production:
* Create pull request from ogee_dev to main
* CI runs again on PR to validate
* Code review and approval required
* Merge triggers production deployment


#### Production Execution:
* Infrastructure changes deploy automatically (if any)
* Pipeline runs on merge (if code changed)
* Pipeline also runs daily at 2 AM UTC for scheduled data processing

This approach ensures:

* Automated testing catches bugs early
* Infrastructure and code changes are tracked separately
* Dev environment mirrors production for safe testing
* Production deployments are controlled and reviewable
* Scheduled runs keep data fresh without manual intervention

#### GitHub Secrets Configuration
The workflows require the following secrets (configured in GitHub Settings → Secrets):
Shared:

SNOWFLAKE_ACCOUNT

Development:
* SNOWFLAKE_DEV_USER
* SNOWFLAKE_DEV_PASSWORD
* SNOWFLAKE_DEV_ROLE
* SNOWFLAKE_DEV_WAREHOUSE

Production:
* SNOWFLAKE_PROD_USER
* SNOWFLAKE_PROD_PASSWORD
* SNOWFLAKE_PROD_ROLE
* SNOWFLAKE_PROD_WAREHOUSE

This secrets-based approach ensures credentials are never exposed in code and can be rotated independently per environment.

#### Branch Protection Rules:

Applied to main branch

| Rule        | Purpose    |
|-------------|------------|
| Require PR before merging  | Prevents direct pushes
| Require status checks    | Tests + lint must pass
| Reject when CI fails    | Guarantees pipeline integrity

#### Result:
* You cannot merge to main unless:
* Pull Request is opened from dev
* CI/CD passes successfully
* Code review is approved
This ensures clean, stable, production-ready code.

### Final Summary

This project demonstrates a full, production-grade ELT workflow with:

* Bronze (raw ingestion)
* Silver (cleaning & transformations)
* Gold (aggregations & KPIs)
* Incremental logic powered by Snowflake Streams
* Python orchestration for execution, logging, retries, and metadata
* Automated testing via pytest
* Linting via flake8
* CI/CD: GitHub Actions + branch protection
* Scheduling via cron
This forms a robust, scalable, maintainable pipeline suitable for real production workloads.



