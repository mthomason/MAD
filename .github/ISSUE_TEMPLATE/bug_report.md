---
name: Bug report
about: Report a defect in the engine, the CLI, the drivers, or the app
title: ''
labels: bug
assignees: ''
---

**What went wrong**
A clear description of the defect and where it lives (engine, `mad` CLI, a
driver, the app).

**To reproduce**
Steps, the exact command line, or a document/query that triggers it. For a
document, attach the smallest `.mad` that shows it (it is a definition, not a
dataset — no row data is in it).

**Expected**
What should have happened.

**What happened instead**
The observed behaviour, with the output or error text verbatim.

**Environment**
- Version or commit: 
- OS and platform (macOS/iOS/Linux, Docker image tag): 
- Database and driver, if applicable: 

**The failing test**
This project is test-first: the issue report that pins the behaviour with a
failing test (or points at the existing test that should have caught it) gets
fixed first. A failing test is not required to report, but it is the fastest
path from report to fix.
