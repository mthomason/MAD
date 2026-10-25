# MAD Scripting: the Scrimpter revival question, the formula element, and the alternatives

*Written 2026-10-23. Status: analysis, recommendation pending the user's decision. This document
answers the four questions asked of `Scrimpter` — can it be made correct, tested, integrated, and
is its design right — and compares the alternatives (including the C# question) and the licensing
surface of each. It records facts, not a queue: nothing here starts work.*

---

## 1. The question

The designer's element palette was meant to include a **scriptable field** — a formula element —
and `Scrimpter` was written (June 2014) as the scripting language for it. The user removed it as
too much to maintain, and is now asking, with AI agents available:

1. What is the state of `Scrimpter`?
2. What would it take to make it correct, add tests, and fully integrate it?
3. Is the design correct?
4. Is this a good idea, or is there a better language already supported? (The user remembers "a
   C# variant" — evaluated in §6.)

The headline answer: **the formula element is half-built in the app already, but the engine is
not in the app at all. Scrimpter is a 2014 interpreter with a broken build, a conflicting
grammar, and several real bugs — all fixable, none of them secretly fine. C# has no practical
path on iOS. The engine decision is deferred by the user's direction (2026-10-23): no new
language will be created, speed and portability matter, and when the work is started the
implementing agent must come back and ask the user to choose the engine (§8).**

## 2. What Scrimpter is today

### 2.1 Shape and size

* `Scrimpter/` is a **standalone Xcode project, not in the workspace** (`Reports.xcworkspace`
  lists every framework except it). It builds a **static library** (`libScrimpter.a`), not a
  framework, with an XCTest bundle. There is no shared scheme — only a user scheme, so CI and
  `xcodebuild test -scheme` cannot reach it (`Scrimpter/AGENTS.md` admits this).
* **~2,340 lines of Objective-C** across 44 files: a lexer spec (`scanner.lm`, 144 lines), a
  yacc grammar (`parser.ym`, 296 lines), an AST class cluster (`MTAbstractSyntaxTree` +
  17 `MTAstNode*` subclasses), a symbol table, and a value wrapper (`MADValue`).
* **47 test methods** in `ScrimpterTests.m` pin arithmetic, precedence, comparisons, if/else,
  variables, strings, comments, method-call functions (`power`, `ceil`, `mod`, `concat`, …),
  and one error case. They are the best part of the project.
* **Original work**: every file is copyrighted to Michael Thomason. No third-party language
  source anywhere. (The `origin/scrimpter` branch is stale 2014 app history, 3,433 commits
  behind master — not the language's development branch; ignore it.)

### 2.2 History

Written June 2014 (file dates), moved/improved through 2014, merged (`e9d52f544`), then parked.
Last substantive commit: **2024-07-23** ("Fixed some bugs"). Critically, the `MADDataStructures`
API it depends on was reworked **2016-03** (`bff7e576e`, `78a3cf3c1`) — and Scrimpter was never
updated. It has been uncompilable in any sense since then, and was never linked into the app:
no `MADDesigner` project file ever referenced `Scrimpter`.

### 2.3 Build state — tested empirically 2026-10-23

| Step | Result |
|---|---|
| `xcodebuild -target Scrimpter` | Fails immediately: `IPHONEOS_DEPLOYMENT_TARGET` is 8.0/8.2; current Xcode requires ≥ 15.0 |
| Same with target override to 15.0 | Xcode's Lex/Yacc build rules **still exist** and run, but `LEX = /opt/local/bin/flex` and `YACC = /usr/local/bin/yacc` do not exist on any current Mac → "unable to spawn process" |
| System tools | `/usr/bin/flex` 2.6.4 exists. `/usr/bin/bison` and the Xcode toolchain bison are both **2.3**, which rejects `%code requires` (`parser.ym:42`) — added in bison 2.4. No Homebrew bison. So no present toolchain on this machine can generate the parser |
| Grammar generation (test-only patch of `%code requires` → prologue) | bison 2.3 generates, reporting **19 shift/reduce and 22 reduce/reduce conflicts**, plus a useless nonterminal (`expstr`, `parser.ym:153` — strings only parse through `term`) |
| Syntax-check of generated parser/scanner + all 30 source files against the iOS 27.1 SDK | All errors are **MADDataStructures API drift**, nothing else: `[MTPair pairWithLeft:andRight:]` is now `newPairWithLeft:andRight:` (`MADDataStructures/Source/MTPair.h`), and `MTTree initWithLeftTree:andRightTree:` is now `initWithData:leftTree:rightTree:` (`MTTree.h`). Mechanical renames in ~6 files |

The dangling `MADDataStructures.framework` reference inside the project was already deleted
2026-10-01 (`BUGS_FIXED.md`, "Three library references named directories that were never
created"); re-linking would go through the workspace's shared `BUILT_PRODUCTS_DIR` like every
other framework. The Linux build excludes Scrimpter entirely — no `Linux/cmake/ScrimpterSources.cmake`,
and the image has no flex/bison (`MAD_LINUX.md` §3: "0 Apple imports, but unused").

**Verdict:** the build breaks in four independent layers — deployment target, tool paths, bison
version, and a 2016 API drift. Each fix is small and mechanical; none was ever applied.

## 3. Correctness audit — the verified bug list

Ordered roughly by severity. Every item is reproduced from the source or from generation output.

### Critical

1. **`while` hangs the parser.** `parser.ym:130`: `stmt: WHILE exp DO list { while ($2) { $$ = $4; } }`.
   The loop runs **at parse time**, and `$2` is an AST pointer that never becomes nil — an
   infinite loop. Any script containing `while` hangs the app. No test covers `while`; the AST
   class that should implement it (`MTAstNodeFlow`, `SCFlowTypeWhile`, `initLoopWithList:`) exists
   but is never constructed.
2. **Multi-argument function calls crash.** `MTAbstractSyntaxTree.m:188-191`:
   `initWithExpression:andList:` (the factory the parser calls for `expr(a, b, …)`) allocates an
   `MTAstNodeStatementList` and sends it `initWithExpression:andList:` — a selector that class
   does not implement (it only has `initWithStatement:andList:`). Unrecognized selector at
   runtime. No test passes two arguments to one call (the chain tests are single-argument each).
3. **The grammar is deeply ambiguous.** No `%left`/`%right` declarations; comparisons appear in
   two overlapping productions (`exp COMPARESON exp` and `expnum COMPARESON factor`). 19 s/r +
   22 r/r conflicts are resolved by yacc defaults, so parsing is deterministic only by accident
   of generation order. Precedence behavior that tests pass today is not guaranteed by the grammar.
4. **Boolean→number conversion is inverted.** `MADValue.m:60`: `r = [self.value boolValue] ? 0 : 1.0;`
   — `true` converts to 0, `false` to 1. Any arithmetic involving a boolean is wrong.

### Substantive

5. **The data-binding half was never finished.** `MADSymbol.h:20` declares `ScrimptData` (the
   host's `dataForkey:` lookup), and `MADScrimpter.m:45` sets it — but **no AST node ever calls
   it**. There is no language syntax to read a field value. The only data path would be the host
   pre-seeding the symbol table, for which there is no public API either. The `ScrimpterDataSource`
   protocol is a vestigial limb.
6. **No date type.** `MADValue` supports double, string, boolean, null. BI formulas need dates
   (the report formatter already special-cases them in `RptqDocumentElement+Extras.m
   -formattedString:forValue:`). A formula language without dates can't do "days overdue".
7. **User-defined functions are a dead class.** `MTAstNodeFunctionCallUserDefined` overrides no
   `evaluate`, is never constructed (there is no function-definition syntax), and would return
   Null if it were.
8. **`return` does not terminate a statement list.** `MTAstNodeStatementList.m:25` checks
   `statement.nodetype != SCNodeTypeResult` — but `statement` is the `MTAstNodeStatement` wrapper
   (type `SCNodeTypeStatement`), so the check never fires and every statement after a `return`
   still evaluates. Harmless for pure expressions, a landmine the day a function has side effects.
9. **Weak strings as identity.** `MADSymbol.name` (`MADSymbol.h:26`) and
   `MADSymbolReference.symbol` (`MADSymbolReference.h:11`) are `weak` NSString properties. The
   strings are kept alive today only because NSString literals and tagged pointers never die.
   One symbol created from a non-literal source and the symbol table silently forgets its name.
10. **NaN guards are dead code.** `MTAstNodeFunctionCallEmbedded.m:108`: `if (base != NAN)` —
    `NaN != NaN` is always true, so the guard never fires; only the later `isnan(r)` catches it.
    Works by accident.
11. **Not re-entrant, not thread-safe.** The engine's whole state is globals: the blocks
    `ScrimptSymbolTable/ScrimptData/ScrimptSymbol/ScrimptSymbolReference/Scrimpted`
    (`MADSymbol.m:11-14`, `MADScrimpter.m:14`) plus flex/bison's `yylval`/`yylloc` globals. Two
    `MADScrimpter` instances (or one used from two threads — exactly what a viewer evaluating
    many formula elements would do) corrupt each other. `run:completion:` is also fully
    synchronous despite the block API.
12. **Bare error messages.** Parser errors surface as "syntax error" with no `YYERROR_VERBOSE`
    and no location from the parser side (scanner errors do carry locations and are pinned by
    `testError`). `lyyerror` (`parser.ym:278`) is dead — bison 2.3 calls plain `yyerror` (verified
    in the generated code, so there is no signature-mismatch crash — but also no location).

### Design smells (not bugs, but they matter for maintenance)

13. `MTAbstractSyntaxTree.m:110-173`: `initWithExpression:` has a 17-case switch in which every
    case is identical. Dead structure.
14. `MTAbstractSyntaxTree.m:269`: `debugQuickLookObject` hardcodes the node type string
    "MTAstNodeNumberValue" for every node.
15. Scanner gaps (`scanner.lm`): identifiers are `[a-zA-Z]+` only (no digits/underscores), numbers
    have no exponent or leading-dot form, only `//` comments, `let` is scanned but has no
    production, and the `|` character is accepted as unary minus alongside `-`.
16. Soft-fail semantics: `"Michael" + " " + "Thomason"` evaluates to **0** (strings coerce to
    double 0), pinned deliberately by `testConcatByStringAddingSoftFail`. That is "not an
    accident" in the ROADMAP sense — but it is also not something a user would guess.

**Verdict:** the interpreter core needs a rewrite in practice. The AST node classes survive (after
the API renames); the grammar, the evaluation-order logic, the value model, and the state model
do not.

## 4. What it would take — the four asks

### 4.1 Make it correct

1. **Build layer** (~half a day, mechanical): deployment target → 15.0; `LEX`/`YACC` → the Xcode
   toolchain (`$(DEVELOPER_DIR)/Toolchains/…/usr/bin/flex|bison`) **or** check in the generated
   parser/scanner and drop the toolchain dependency entirely (recommended — it also unblocks the
   Linux image, which has no flex/bison); the six-file `MADDataStructures` rename; add the project
   to the workspace with a shared scheme.
2. **Grammar layer** (2–4 days): restructure to zero conflicts — precedence declarations, one
   comparison production, remove `expstr`, keep `%code requires` only if regenerating with modern
   bison (or drop it). Grammar actions must build AST nodes **only** — this is what eliminates
   the `while` hang by construction.
3. **Semantic layer** (2–5 days): fix the bool conversion; make `while` an AST node evaluated by
   `MTAstNodeFlow`; implement multi-argument function calls; make `return` terminate; make NaN
   handling explicit; either wire `ScrimptData` into a `data(key)`-style production or add a
   public symbol-seeding API; decide the date story (wrap `NSDate` in `MADValue`); kill the dead
   user-function class or implement user functions.
4. **State layer** (1–2 days): move the block globals into a per-run context (`%parse-param`,
   reentrant flex `yylex`); make `run:` contract explicit (synchronous) and safe to call from
   any thread.

### 4.2 Add tests

The 47 existing tests are a genuine asset — they pin today's semantics, so a rewrite has a
regression net from day one. What's missing:

* A runnable target: shared scheme + workspace membership + working links (the `AGENTS.md`
  command for Scrimpter currently names `-scheme None`, which does not exist).
* New suites for exactly the verified gaps: `while` (the hang), multi-arg calls (the crash),
  boolean arithmetic, dates, NaN/null propagation, parser error cases (not just scanner errors),
  data-source binding, and re-entrancy (two interleaved runs).
* If Scrimpter joins the headless engine: a `Linux/cmake/ScrimpterSources.cmake` + ported suite
  (the image gets the generated parser via checked-in files — see 4.1.1).

### 4.3 Fully integrate — the formula element

This is the good news, discovered by tracing the barcode template end to end: **the formula
element is already half-built at the model layer.**

* `MADPrintPageElementTypeFormula = 4` exists (`MAD/Source/MADDocumentObjectType.h:19`).
* `RptqDocumentElementFormula` exists with `functionScope`, `functionType`, `inputType`, `name`,
  `resultType`, and **`source`** — the natural storage slot for script text
  (`MAD/Source/rptq/autogen/RptqDocumentElementFormula.h`). It is persisted in the portable store
  schema (`MADStoreSchema.m:603-612`) and has a creation factory
  (`RptqDocumentElementFormula+Extras.m:37-57`).
* Aggregates even declare formula inputs (`MADAggregateFunctionInputType` Field/Formula) — never
  evaluated.

What is missing (mirroring the barcode end to end, `MADBarcodes` + `RptqDocumentElementBarcode` +
`MADDesignerElementBarcodeView` + `MADDocumentObjectDataReferenceBarcode` +
`MADPrintPageElementBarcode`):

1. Palette entry + a formula designer view controller (the picker has a dormant
   `MADViewTagFieldOrFormulaSelector` hook at `MADDesignerElementPickerViewController.m:259-269`).
2. A designer element view (today the designer renders Formula as a plain text label —
   `MADDesignerViewController.m:1854-1858`).
3. The viewer pair: `MADDocumentObjectDataReferenceFormula` + `MADPrintPageElementFormula`, with
   the case at `MADPrintPageElement+Constructor.m:51` **uncommented**, computing the value per
   row from the render data source (`MADDocumentRenderDataSource`, `dataForRow:column:error:`).
4. The evaluation hook itself — nothing references Scrimpter anywhere in the app today.

The model and schema work is done; the cost is UI + viewer plumbing plus the engine. **That cost
is identical no matter which engine is chosen** — the engine is one `case` at the end.

### 4.4 Is the design correct?

The architecture is the textbook shape for a small embedded language — lexer → parser → AST →
tree-walk evaluator, symbol table with reference tracking, a boxed value type, a host data
protocol — and the right answer is to keep it. What is wrong is where it deviates from that
shape: **evaluation inside grammar actions** (the `while` hang), no precedence layer, **globals
instead of a parser context**, and features designed but not finished (data binding, user
functions). Fixing the design *is* fixing the correctness list — they are the same work. The
AST node cluster (roughly half the code) survives as-is.

Honest total: making Scrimpter correct, tested, and integrated is **4–6 weeks** of focused work
with AI assistance, then **permanent language maintenance** — docs, a language reference for
users, error-message quality, and every future feature twice (language + app). The AI-agent
premise is sound: the reason custom languages were risky was documentation and upkeep cost, and
agents genuinely change that. The question is whether the language earns its keep — §6.

## 5. The engine decision — JavaScriptCore, and why it wins

For the *formula element*, the candidate set:

| Engine | Third-party code | License surface | Dates | Re-entrant | Headless/Linux | Users know it |
|---|---|---|---|---|---|---|
| **JavaScriptCore** (system framework) | none | none — Apple system framework | built-in `Date` | one `JSContext` per evaluation | no (Apple-only) | yes — JavaScript |
| **QuickJS** (with JSC, as the Linux half of a JS pairing) | yes (C) | MIT — attribution + license text (docs/project/THIRD_PARTY_LICENSES.md §6/§7) | built-in `Date` | yes | yes | yes (JS) |
| **Scrimpter** | none (own code) | none | missing today | no (globals) | portable (ObjC+GNUstep) | no |
| **Lua 5.5** | yes (~25k lines C) | MIT — attribution + license text (docs/project/THIRD_PARTY_LICENSES.md §6/§7) | no native date | yes | yes | some |
| **Wren** | yes (~4k lines C) | MIT — same obligations | no | yes | yes | no |
| **NSExpression** (Foundation) | none | none | yes | yes | partial (GNUstep has it) | no — and no control flow/variables, expression-only |
| **C# / .NET** | — | — | **not viable**, see below | — | — | — |

One clarification, because it changes the trade: **JavaScriptCore is not macOS-only.** It is a
system framework on every Apple platform, iOS included (since iOS 7 — it is the engine behind
WKWebView, and `JSContext` is fully available to iOS apps). What it is not is *portable*: the
Linux headless image cannot link any Apple framework. That is the only gap, and the JS pairing
below exists to close it.

**On the merits, for the formula field:**

* **Zero licensing and zero maintenance.** It is a system framework — nothing ships in the
  binary, nothing enters the license-compliance plan, and Apple maintains the engine. The thing
  an agent would otherwise have to keep correct forever is already someone else's job.
* **Users already know the language.** A formula field that is "a small JavaScript expression"
  needs no language reference; `amount * quantity`, `price > 100 ? "HIGH" : "LOW"`, `date1 -
  date2` are all self-explanatory and Google-answerable.
* **Dates, strings, numbers, null bridge for free** (`NSString`/`NSNumber`/`NSDate`/`NSNull` ↔
  `JSValue`), which is exactly the value surface a report field needs.
* **Sandboxed by design** — a `JSContext` has no filesystem, no network, no globals unless the
  host grants them; a formula element can simply be given its row fields and a few functions.
* **App-review clean.** Guideline 2.5.2 concerns downloaded code run by custom interpreters;
  JavaScriptCore is Apple's own engine and user-typed formulas are document data (the app
  already ships user-authored SQL). No exposure.
* **Known cost:** on iOS JavaScriptCore runs interpreted (no JIT entitlement for third-party
  apps) — 3–5× slower than desktop JS. For per-row formulas over the row cache this is
  irrelevant (microseconds per evaluation), and every alternative on this list is interpreted
  too. One `JSContext` per document refresh (row values set per row, not per evaluation) keeps
  even large reports fast.

**The C# question, answered:** there is no practical C# scripting option on iOS. .NET on iOS is
AOT-only — `System.Reflection.Emit` and runtime compilation are forbidden by the OS's no-JIT
model, and Mono's interpreter cannot execute dynamically generated assemblies. Scripting C#
would require Roslyn (unsupported on iOS) plus a hand-written IL interpreter, or embedding the
Mono runtime dylib into an ObjC app — a research project measured in hundreds of megabytes and
license obligations. The "C# variant" memory was likely NCalc or similar — a .NET library, not
an embeddable engine. Drop this path.

**The one real argument against JavaScriptCore** is the headless engine: the `mad` CLI and the
future Linux PDF writer cannot link JSC, so formula elements could not be evaluated there.
Today nothing headless renders pages (`MAD_PDF_LINUX.md` is deferred), so this costs nothing
now; if it ever matters, the escape hatch is clean — pick JavaScript as the *language* and run
it on **QuickJS** (MIT, pure C) in the Linux image. Formulas written for JSC run identically on
QuickJS.

## 6. Scrimpter's honest paths

Three, and the user has closed one:

1. **Resurrect as the formula engine — not recommended.** The correctness audit shows this is a
   rewrite, then a permanent second product (language + docs + maintenance) to solve a problem
   JavaScriptCore already solves with zero obligations. The 2014 interpreter does not contain
   treasure that outweighs this; it contains a fine AST cluster and a broken grammar.
2. **The language as its own product — declined by the user (2026-10-23).** `MAD_FUTURE.md` §7
   makes the real case for a report DSL as the AI-era textual form of a document, and the
   spec-first/transpile-to-JS path above was the defensible version of it — but the user is not
   passionate about creating a new language, and "it's embedded" is not a reason on its own.
   This path is out of the running; the `MAD_FUTURE.md` §7 vision itself is unchanged and can be
   revisited independently of the formula element.
3. **Leave it parked.** The framework is not in the workspace, not built, not linked, and its own
   AGENTS.md says not to use it. The git history keeps everything; `MAD_SCRIPTING.md` records why
   it stays parked. Deleting outright remains an option, but nothing requires it.

## 7. Licensing summary

* **Scrimpter (if kept):** the user's own copyright — no obligations. Regenerating the parser:
  bison's output carries the GPL-with-exception text; the exception permits proprietary use, and
  the notice must stay in the generated file. flex output imposes nothing (flex is BSD-style,
  and ≥ 2.5.4 embeds no notice in the generated scanner). Both are App Store-ordinary.
* **JavaScriptCore:** Apple system framework — nothing shipped, no notices, nothing added to
  `THIRD_PARTY_LICENSES.md`.
* **Lua / Wren / QuickJS:** MIT — permitted, but each adds a row to the compliance plan
  (`THIRD_PARTY_LICENSES.md` §6/§7): carry the license text, add the attribution surface, keep
  the inventory entry current. Not a blocker; a real, ongoing obligation.
* **C#/.NET:** moot (not viable), and would have been the heaviest of all.
* **App Store:** user-typed formulas are document data, like the SQL the app already executes.
  JavaScriptCore is Apple's own engine, so guideline 2.5.2 does not apply to it. A custom
  interpreter (Scrimpter, Lua) running user-authored script is also within the guidelines, but
  JSC removes the question entirely.

## 8. Recommendation

**The engine decision is deferred, by the user's direction (2026-10-23).** What is settled:
C# is dead; **there will be no new language** (the user is not passionate about one, and one
would exist only to be called "embedded"); speed and portability matter. When the formula
element work is started — a `TASKS.md` entry, created only at the user's request — **the
implementing agent must come back and ask the user to choose the engine** from the shortlist
below. This document is the context for that question, not the answer to it.

The shortlist, in light of those criteria:

1. **JavaScript, run by JavaScriptCore on Apple and QuickJS in the Linux image.** The language
   users already know; dates built in; zero licensing on the Apple side, one MIT row on the
   Linux side; one language, two engines. This is the most portable way to keep JavaScript, and
   it keeps the formula feature free of engine maintenance.
2. **Lua 5.5.** The fastest interpreter of the set and the most portable single engine — one
   MIT codebase everywhere, headless included. Cost: third-party code with attribution
   obligations, no native dates (a wrapper is needed), an ObjC bridge to write, and a language
   end users mostly don't know.
3. **Wren.** Small, MIT, portable; class-based syntax that reads closer to C-like expectations.
   Cost: the most niche option, fewer eyes, no dates.
4. **NSExpression.** System, zero cost, portable via GNUstep — but expression-only (no control
   flow, no user variables). Only in play if the "scriptable field" shrinks to a "formula
   field".

Scrimpter stays parked (§6); the `MAD_FUTURE.md` §7 AI-DSL vision is unchanged and independent
of this decision. The formula element's model layer (`MADPrintPageElementTypeFormula`,
`RptqDocumentElementFormula.source`, the store schema) is engine-agnostic and remains ready for
whichever engine is chosen.

## Sources

* React Native — JavaScript environment (JavaScriptCore, no JIT on iOS):
  https://reactnative.dev/docs/javascript-environment
* NativeScript — iOS runtime (JIT disabled in App Store builds):
  https://v7.docs.nativescript.org/core-concepts/ios-runtime/overview
* outl RFC 0025 — plugin engine selection (iOS bans JIT; interpreters chosen over JSC for
  portability): https://github.com/outlmd/outl/blob/main/docs/rfcs/0025-plugin-system.md
* App Store guideline 2.5.2 in practice (WebKit/JavaScriptCore exempt):
  https://appcompliance.io/blog/guideline-2-5-2-rejection/
* Microsoft Learn — .NET on iOS/Mac Catalyst interpreters (AOT default, Mono interpreter
  limits): https://learn.microsoft.com/zh-cn/dotnet/maui/macios/interpreter?view=net-maui-10.0
* dotnet/runtime discussion #112420 — embedding the Mono runtime in a plain iOS app (the
  state of the art for "C# on iOS", and why it is not scripting):
  https://github.com/dotnet/runtime/discussions/112420
* Lua 5.5 release (2025-12-22, MIT, C): https://www.opennet.dev/opennews/art.shtml?num=64476
* Wren vs Lua comparison (both MIT; Wren ~4k lines C, recent activity):
  https://www.libhunt.com/compare-wren-vs-LuaDist--lua
