<!-- last-reconciled: abc1234 -->
# Sample App Architecture

## Overview
A simple task management application with a REST API and a web frontend.

## Component map
### Component: API
- **Responsibility:** Serves task CRUD operations over HTTP.
- **Depends on:** Database
- **Key interfaces:** `GET/POST/PUT/DELETE /api/tasks`
- **Location:** `src/api/`

### Component: Database
- **Responsibility:** Stores tasks persistently.
- **Depends on:** (none)
- **Key interfaces:** SQLite file at `data/tasks.db`
- **Location:** `src/db/`

### Component: Web frontend
- **Responsibility:** Renders the task UI in the browser.
- **Depends on:** API
- **Key interfaces:** `index.html`, `app.js`
- **Location:** `src/web/`

## Key interactions
1. Task create: browser -> POST /api/tasks -> API -> Database -> response
2. Task list: browser -> GET /api/tasks -> API -> Database -> response -> render

## Tech stack & constraints
- **Languages / frameworks:** Python (API), SQLite (Database), vanilla JS (frontend)
- **Key constraints:** Single-process deployment; no external services

## Roadmap
### Done
- Initial API -- docs/superpowers/specs/2026-01-01-initial-api-design.md

### In progress
- Add notifications -- docs/superpowers/specs/2026-06-28-notifications-design.md

### Planned
- User authentication
