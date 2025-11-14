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
.github/workflows/ci.yml runs:
pytest
* flake8
* dependency installation
* pull-request validation
* scheduled jobs (cron)

CI runs on every push to the dev branch (ogee_dev)
CI Workflow Summary:
```
```

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



