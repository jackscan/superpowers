<!-- last-reconciled: PLACEHOLDER -->
# Demo App Architecture

## Overview
A demo application with an API and a worker.

## Component map
### Component: API
- **Responsibility:** Serves HTTP requests.
- **Depends on:** Database
- **Key interfaces:** `GET /api/items`
- **Location:** `src/api/`

### Component: Database
- **Responsibility:** Stores items.
- **Depends on:** (none)
- **Key interfaces:** SQLite at `data/demo.db`
- **Location:** `src/db/`

### Component: Worker
- **Responsibility:** Runs background tasks.
- **Depends on:** (none)
- **Key interfaces:** `src/worker/worker.py`
- **Location:** `src/worker/`

## Key interactions
1. Item fetch: client -> GET /api/items -> API -> Database -> response
2. Background task: Worker -> process queue

## Tech stack & constraints
- **Languages / frameworks:** Python (API, Worker), SQLite (Database)
- **Key constraints:** Single-process

## Roadmap
### Done
- Initial API -- abc000
- Background worker -- <dynamic commit ref>

### In progress

### Planned
