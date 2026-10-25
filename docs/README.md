# The `.mad` Document Format

This document defines what a `.mad` file is. It describes the format **as it exists
today**, taken from two shipping sample documents and the code that reads and writes
them, and then states the format **as it should be defined** so that a reader on
another platform -- a command-line tool, a Windows build -- can open a document
without relying on Core Data or on any Apple framework.

Everything in the first half is measured, not inferred. The two samples are
`../MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad` and
`…/London.dataset/London.mad`.

---

**The `.mad` format is an open specification.** Anyone may read it and implement
it. The MIT licence covers the project's code, not the project's name -- "MAD
Designer" is the author's name for the product, and nothing in this repository
licenses its use. See [`../LICENSE`](../LICENSE) and
[`../THIRD_PARTY_LICENSES.md`](../THIRD_PARTY_LICENSES.md).

The spec is organised as one chapter per file. Chapters 1-6 describe the format as
it ships; chapter 7 is the normative target (`v1`); chapters 8-9 are the open
questions and how the claims are verified:

1. [What a document is, in one sentence](01-document.md)
2. [The container](02-container.md)
3. [The store](03-store.md)
4. [Reading and writing, as implemented](04-reading-writing.md)
5. [What is *not* in the document: the companion files](05-companion-files.md)
6. [Hazards a second reader must handle](06-hazards.md)
7. [The format as it should be defined](07-normative.md)
8. [Open questions](08-open-questions.md)
9. [Verification](09-verification.md)
