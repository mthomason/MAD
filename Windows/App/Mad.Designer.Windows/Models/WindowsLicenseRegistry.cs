//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Models;

/// <summary>One redistributed component and the licence text that must travel with it.</summary>
public sealed record WindowsComponent(
    string Name,
    string License,
    string Details,
    string LicenseTitle,
    string LicensePath);

/// <summary>The Windows engine's dependency register, mirrored from
/// <c>docs/project/THIRD_PARTY_LICENSES.md</c> §10 and <c>ThirdParty/Licenses/Windows/</c>. It lists
/// the Windows component set only — never the Apple app's (no zint, libpng, Font Awesome, …).</summary>
public static class WindowsLicenseRegistry
{
    public static IReadOnlyList<WindowsComponent> Components { get; } = new List<WindowsComponent>
    {
        new("GNUstep Base", "LGPL-2.1-or-later",
            "The Objective-C Foundation framework the native Windows engine is built on.",
            "GNU Lesser General Public License v2.1 (GNUstep Base, libiconv, gnustep-corebase)",
            "Windows/LGPL-2.1.txt"),
        new("libiconv (library)", "LGPL-2.1-or-later",
            "The character-set conversion library. The iconv command-line tools are GPL and are not shipped.",
            "GNU Lesser General Public License v2.1 (GNUstep Base, libiconv, gnustep-corebase)",
            "Windows/LGPL-2.1.txt"),
        new("gnustep-corebase", "LGPL-2.1-or-later",
            "GNUstep's Core Foundation-compatible base library.",
            "GNU Lesser General Public License v2.1 (GNUstep Base, libiconv, gnustep-corebase)",
            "Windows/LGPL-2.1.txt"),
        new("libobjc2", "MIT",
            "The Objective-C runtime (including libBlocksRuntime).",
            "MIT License (libobjc2)",
            "Windows/libobjc2-MIT.txt"),
        new("libdispatch", "Apache-2.0 with the Swift runtime exception",
            "Grand Central Dispatch for Windows (swift-corelibs-libdispatch).",
            "Apache License 2.0 with the Swift runtime exception (libdispatch)",
            "Windows/libdispatch-Apache-2.0-with-Swift-exception.txt"),
        new("libffi", "MIT",
            "The foreign function interface library.",
            "MIT License (libffi)",
            "Windows/libffi-MIT.txt"),
        new("SQLite", "Public domain",
            "The embedded SQL database used for portable documents and local row caching.",
            "SQLite Blessing",
            "sqlite3-LICENSE.md"),
        new("zlib", "zlib License",
            "Compression library.",
            "zlib License",
            "zlib-LICENSE.txt"),
        new("bzip2", "bzip2 License",
            "Compression library used by the .mad container.",
            "bzip2 License",
            "bzip2-LICENSE.txt"),
        new("libarchive", "BSD-2-Clause",
            "Archive library used to read and write the .mad container.",
            "BSD 2-Clause License (libarchive)",
            "libarchive-BSD-2-Clause.txt"),
        new("OpenSSL", "Apache-2.0",
            "TLS library used by the database drivers.",
            "Apache License 2.0 (OpenSSL)",
            "openssl-Apache-2.0.txt"),
        new("FreeTDS", "LGPL-3.0",
            "The TDS client library for Microsoft SQL Server. One installed header (sybdb.h) is modified, as marked in the file.",
            "GNU Lesser General Public License v3.0 (FreeTDS)",
            "LGPL-3.0.txt"),
        new("MariaDB Connector/C", "LGPL-3.0",
            "The MariaDB/MySQL client library.",
            "GNU Lesser General Public License v3.0 (MariaDB Connector/C)",
            "LGPL-3.0.txt"),
        new("libpq", "PostgreSQL License",
            "The PostgreSQL client library.",
            "PostgreSQL License (libpq)",
            "postgres-LICENSE.txt"),
    };

    public static string RelinkOffer { get; } = ReadRelinkOffer();

    public static string BrandNotice { get; } =
        "Licensed under the MIT License. The names \"MAD\", \"MAD Designer\", and \"MAD Viewer\" and the application icons and artwork are not licensed under the MIT License; all rights in them are reserved by Michael Thomason.";

    public static string OverviewText { get; } =
        "MAD Designer is open-source business intelligence software by Michael Thomason.\n\n" +
        "MAD is an open-source mobile business intelligence and report-design system. A .mad file stores a report's schema snapshot, query definition, and visual layout in one compact, portable document.\n\n" +
        "MAD Designer connects natively to MySQL / MariaDB, Microsoft SQL Server, and PostgreSQL databases, and uses SQLite for portable sample documents and local row caching.\n\n" +
        "On Windows, MAD Designer is a WPF application that drives the native Windows engine (mad.exe) over a JSON process boundary. PDF export is deferred on Windows and Linux; HTML, CSV, JSON, and plain-text export are available.";

    public static string? ReadLicenseText(WindowsComponent component)
    {
        string path = Path.Combine(MadPathResolver.LicensesRoot(), component.LicensePath);
        return File.Exists(path) ? File.ReadAllText(path) : null;
    }

    private static string ReadRelinkOffer()
    {
        string readme = Path.Combine(MadPathResolver.LicensesRoot(), "README.md");
        if (File.Exists(readme))
        {
            string text = File.ReadAllText(readme);
            const string marker = "## The relink offer (the native Windows engine)";
            int start = text.IndexOf(marker, StringComparison.Ordinal);
            if (start >= 0)
            {
                int end = text.IndexOf("\n## ", start + marker.Length, StringComparison.Ordinal);
                string section = end >= 0 ? text[start..end] : text[start..];
                return section.Trim();
            }
        }
        return FallbackRelinkOffer;
    }

    private const string FallbackRelinkOffer =
        "## The relink offer (the native Windows engine)\n\n" +
        "The native Windows engine (Windows/, mad.exe and the WPF app that will host it) distributes GNUstep Base, libiconv and gnustep-corebase (LGPL-2.1-or-later), and links FreeTDS and MariaDB Connector/C statically under the same LGPL-3.0 election as the Apple app. To exercise your right to relink the application, contact mthomason [at] gmail [dot] com to receive the object files and build materials needed to do so.";
}
