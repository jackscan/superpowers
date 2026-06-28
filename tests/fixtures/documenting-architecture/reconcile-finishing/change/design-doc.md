# Add Notifications — Design

**Date:** 2026-06-28

## Goal
Add a notifications service that fires when tasks are completed.

## Components
- NEW: Notifications service -- listens for task completion events, sends email.
- MODIFIED: API -- emits a task-completed event to the notifications service.
- New interaction: task complete -> API -> Notifications -> email send
