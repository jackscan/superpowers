<!-- last-reconciled: PLACEHOLDER -->
# Sample App Architecture

## Overview
A simple task management application with a REST API and a web frontend.

## Component map
### Component: API
- **Responsibility:** Serves task CRUD operations over HTTP; emits task-completed events.
- **Depends on:** Database, Notifications
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

### Component: Notifications
- **Responsibility:** Listens for task completion events and sends email notifications.
- **Depends on:** API
- **Key interfaces:** Event subscription on task-completed
- **Location:** `src/notifications/`

## Key interactions
1. Task create: browser -> POST /api/tasks -> API -> Database -> response
2. Task list: browser -> GET /api/tasks -> API -> Database -> response -> render
3. Task complete: API -> task-completed event -> Notifications -> email send

## Tech stack & constraints
- **Languages / frameworks:** Python (API, Notifications), SQLite (Database), vanilla JS (frontend)
- **Key constraints:** Single-process deployment; no external services

## Roadmap
### Done
- Initial API -- docs/superpowers/specs/2026-01-01-initial-api-design.md
- Add notifications -- docs/superpowers/specs/2026-06-28-notifications-design.md

### In progress

### Planned
- User authentication
