**English** | [简体中文](SECURITY_zh.md) | [日本語](SECURITY_ja.md) | [Português (Brasil)](SECURITY_pt-BR.md)

# Security Policy

## Supported versions

Only the latest release receives security fixes. The project has not made a
public release yet; once it has, anything older than the latest release is
unsupported and users are expected to upgrade.

| Version | Supported |
|---|---|
| latest release | :white_check_mark: |
| everything earlier | :x: |

## What is in scope

* The engine and its frameworks: the `.mad` reader and writer, the query
  compiler, the renderers, the drivers (MySQL, SQL Server, SQLite), and the
  `mad` CLI.
* The app itself, for the parts reachable from a document or a connection:
  document parsing, credential storage, and anything that takes a server
  answer or a file as input.

Please remember the trust model: a `.mad` document contains a query, and
opening one is choosing to run a report — the format is a definition, not
sandboxed code, and no code inside a document is ever executed.

## Reporting a vulnerability

**Do not open a public issue.** Report privately:

* Once the repository is published: use GitHub's **Report a vulnerability**
  flow (**Security → Advisories**), which keeps the report confidential and
  lets us publish an advisory with you credited when the fix lands.
* Until then, contact the maintainer directly.

Include, if you can: the affected component and version, a minimal reproducer
or the document/query that triggers it, and the impact you expect. You will
get an acknowledgement within a week and a fix or a written assessment as
soon as one exists.

## Expectations

There is no bug bounty. The project is a solo maintainer's effort; what you
get is a fast, credited fix and a written advisory. Responsible disclosure
(the report stays private until a fix ships) is assumed, and the advisory
names reporters who want to be named.

## Known, accepted trade-offs

These are design decisions, not reportable bugs — they are documented in the
spec and the bug register, and changing them is a product decision:

* The `.mad` container has no magic bytes yet (`docs/06-hazards.md`, hazard
  H1); detection is by extension in the shipping format, with magic bytes in
  the normative `v1`.
* The render cache is keyed by filename and page size, not content
  (`docs/05-companion-files.md` §5.3), so editing a document under the same
  name can serve stale pages until the cache files are removed.
* The test suites' database credentials in
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) are throwaway
  local-docker credentials, not production secrets.
