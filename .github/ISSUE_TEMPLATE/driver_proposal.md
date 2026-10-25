---
name: Driver proposal
about: Propose a new database driver (a MADDatabase subclass)
title: 'Driver proposal: '
labels: driver-proposal
assignees: ''
---

**The database**
Name, version range, and why it is worth a driver.

**The client library**
What the driver would talk to the server with — library, licence, and link
story (static, dynamic, the Compressor recipe it needs). The licence matters:
this repository ships under MIT, and a driver links its client into the app,
so a GPL-only client is a non-starter.

**The surface**
The driver implements `MADDatabase`: connecting, schema discovery, executing
the query the designer generates, and returning rows. Note anything unusual —
dialect quirks, type mappings, pagination, auth.

**The test story**
This project is test-first. Say where the live suite would run: a Docker
container (like `MADMySQL/TestDatabase/`) or a skip-when-unreachable suite
against a public server. The driver-authoring tutorial
([`docs/tutorials/driver-authoring.md`](docs/tutorials/driver-authoring.md))
walks through the whole seam.

**Are you building it?**
Whether this is a proposal you intend to implement or a request for someone
else.
