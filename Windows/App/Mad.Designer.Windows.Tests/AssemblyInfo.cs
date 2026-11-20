//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Xunit;

// The localization tests temporarily change the process-wide language; run the suite
// sequentially so no English-asserting test observes another test's language.
[assembly: CollectionBehavior(DisableTestParallelization = true)]
