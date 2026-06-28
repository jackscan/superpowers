<!-- last-reconciled: OLDER -->
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

## Key interactions
1. Item fetch: client -> GET /api/items -> API -> Database -> response

## Tech stack & constraints
- **Languages / frameworks:** Python (API), SQLite (Database)
- **Key constraints:** Single-process

## Roadmap
### Done
- Initial API -- abc000

### In progress

### Planned
- Background worker
