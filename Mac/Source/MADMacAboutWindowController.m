//
//  MADMacAboutWindowController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacAboutWindowController.h"

static NSString * const kMADGitHubRepositoryURL = @"https://github.com/mthomason/MAD";

@interface MADMacAboutWindowController () <NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate>

@property (nonatomic, strong, nullable) NSBundle *resourceBundle;
@property (nonatomic, assign, readwrite) MADMacAboutTab selectedTab;

@property (nonatomic, strong) NSImageView *appIconImageView;
@property (nonatomic, strong, readwrite) NSTextField *titleLabel;
@property (nonatomic, strong, readwrite) NSTextField *subtitleLabel;
@property (nonatomic, strong, readwrite) NSTextField *versionLabel;
@property (nonatomic, strong, readwrite) NSTextField *copyrightLabel;
@property (nonatomic, strong, readwrite) NSTextField *licenseSummaryLabel;
@property (nonatomic, strong) NSButton *gitHubButton;

@property (nonatomic, strong, readwrite) NSSegmentedControl *sectionSegmentedControl;
@property (nonatomic, strong) NSTabView *contentTabView;

@property (nonatomic, strong, readwrite) NSTextView *overviewTextView;
@property (nonatomic, strong, readwrite) NSTextView *licensingTextView;

@property (nonatomic, strong) NSSplitView *acknowledgementsSplitView;
@property (nonatomic, strong, readwrite) NSTableView *componentTableView;
@property (nonatomic, strong, readwrite) NSTextView *acknowledgementsTextView;

@end

@implementation MADMacAboutWindowController

#pragma mark - Bundle & Metadata Helpers

+ (NSBundle *)resolvedBundle:(nullable NSBundle *)bundle {
	if (bundle != nil) {
		return bundle;
	}
	NSBundle *mainBundle = [NSBundle mainBundle];
	if ([mainBundle pathForResource:@"LGPL-3.0.txt" ofType:nil inDirectory:@"Licenses"] != nil ||
		[mainBundle pathForResource:@"MADMeta" ofType:@"plist"] != nil) {
		return mainBundle;
	}
	NSString *siblingAppPath = [mainBundle.bundlePath stringByAppendingPathComponent:@"MAD Designer.app"];
	NSBundle *siblingBundle = [NSBundle bundleWithPath:siblingAppPath];
	if (siblingBundle != nil) {
		return siblingBundle;
	}
	return mainBundle;
}

+ (nullable NSDictionary *)metaDictionaryForBundle:(nullable NSBundle *)bundle {
	NSBundle *resolved = [self resolvedBundle:bundle];
	NSString *path = [resolved pathForResource:@"MADMeta" ofType:@"plist"];
	if (path.length > 0) {
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
		if (dict != nil) {
			return dict;
		}
	}
	return nil;
}

+ (nullable NSString *)textContentsOfResource:(NSString *)filename
								  inDirectory:(nullable NSString *)directory
									   bundle:(nullable NSBundle *)bundle {
	NSBundle *resolved = [self resolvedBundle:bundle];
	NSString *path = nil;
	if (directory.length > 0) {
		path = [resolved pathForResource:filename ofType:nil inDirectory:directory];
	}
	if (path.length == 0) {
		path = [resolved pathForResource:filename ofType:nil];
	}
	if (path.length == 0 && directory != nil && directory.length > 0 && resolved.resourcePath != nil) {
		NSString *nonnullDir = (NSString * _Nonnull)directory;
		NSString *candidate = [[resolved.resourcePath stringByAppendingPathComponent:nonnullDir]
							   stringByAppendingPathComponent:filename];
		if ([[NSFileManager defaultManager] fileExistsAtPath:candidate]) {
			path = candidate;
		}
	}
	if (path.length == 0) {
		NSString *repoRoot = [[[NSProcessInfo processInfo] environment] objectForKey:@"MAD_REPO_ROOT"];
		if (repoRoot.length > 0) {
			NSString *nonnullDir = (directory != nil && directory.length > 0)
				? ([directory isEqualToString:@"Licenses"] ? @"ThirdParty/Licenses" : (NSString * _Nonnull)directory)
				: nil;
			NSString *repoCandidate = nonnullDir != nil
				? [[repoRoot stringByAppendingPathComponent:nonnullDir] stringByAppendingPathComponent:filename]
				: [repoRoot stringByAppendingPathComponent:filename];
			if ([[NSFileManager defaultManager] fileExistsAtPath:repoCandidate]) {
				path = repoCandidate;
			}
		}
	}
	if (path.length == 0) {
		return nil;
	}
	return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString *)bundleDisplayNameForBundle:(nullable NSBundle *)bundle {
	NSBundle *resolved = [self resolvedBundle:bundle];
	NSString *displayName = resolved.infoDictionary[@"CFBundleDisplayName"] ?: resolved.infoDictionary[@"CFBundleName"];
	return displayName.length > 0 ? displayName : @"MAD Designer";
}

+ (NSString *)versionTextForBundle:(nullable NSBundle *)bundle {
	NSDictionary *meta = [self metaDictionaryForBundle:bundle];
	NSBundle *resolved = [self resolvedBundle:bundle];
	NSString *shortVersion = meta[@"CFBundleShortVersionString"]
		?: resolved.infoDictionary[@"CFBundleShortVersionString"]
		?: @"9.0";
	return [NSString stringWithFormat:@"v%@", shortVersion];
}

+ (NSString *)buildTextForBundle:(nullable NSBundle *)bundle {
	NSDictionary *meta = [self metaDictionaryForBundle:bundle];
	NSBundle *resolved = [self resolvedBundle:bundle];
	NSString *commitCount = [meta[@"MADGitCommitCount"] description]
		?: [resolved.infoDictionary[@"CFBundleVersion"] description]
		?: @"4433";
	return [NSString stringWithFormat:@"r%@", commitCount];
}

+ (NSString *)humanReadableCopyrightForBundle:(nullable NSBundle *)bundle {
	NSBundle *resolved = [self resolvedBundle:bundle];
	NSString *copyright = resolved.infoDictionary[@"NSHumanReadableCopyright"];
	if (copyright.length == 0) {
		copyright = @"Copyright © 2012–2026 Michael Thomason";
	}
	return copyright;
}

+ (NSString *)mitLicenseAndBrandNoticeText {
	return @"Licensed under the MIT License. The names \"MAD\", \"MAD Designer\", and \"MAD Viewer\" and the application icons and artwork are not licensed under the MIT License; all rights in them are reserved by Michael Thomason.";
}

#pragma mark - Content Builders

+ (NSDictionary<NSAttributedStringKey, id> *)headingAttributes {
	return @{
		NSFontAttributeName: [NSFont boldSystemFontOfSize:15.0],
		NSForegroundColorAttributeName: [NSColor labelColor],
	};
}

+ (NSDictionary<NSAttributedStringKey, id> *)subheadingAttributes {
	return @{
		NSFontAttributeName: [NSFont boldSystemFontOfSize:13.0],
		NSForegroundColorAttributeName: [NSColor labelColor],
	};
}

+ (NSDictionary<NSAttributedStringKey, id> *)bodyAttributes {
	NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
	pStyle.lineSpacing = 2.0;
	pStyle.paragraphSpacing = 8.0;
	return @{
		NSFontAttributeName: [NSFont systemFontOfSize:12.5],
		NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
		NSParagraphStyleAttributeName: pStyle,
	};
}

+ (NSDictionary<NSAttributedStringKey, id> *)monospaceLicenseAttributes {
	return @{
		NSFontAttributeName: [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular],
		NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
	};
}

+ (NSAttributedString *)overviewAttributedText {
	NSDictionary *headingAttrs = [self headingAttributes];
	NSDictionary *subheadingAttrs = [self subheadingAttributes];
	NSDictionary *bodyAttrs = [self bodyAttributes];

	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

	void (^appendHeading)(NSString *) = ^(NSString *title) {
		if (result.length > 0) {
			[result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:bodyAttrs]];
		}
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n\n"] attributes:headingAttrs]];
	};

	void (^appendSubheading)(NSString *) = ^(NSString *title) {
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n"] attributes:subheadingAttrs]];
	};

	void (^appendBody)(NSString *) = ^(NSString *paragraph) {
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[paragraph stringByAppendingString:@"\n\n"] attributes:bodyAttrs]];
	};

	appendHeading(@"Mobile Analytics Document");
	appendBody(@"MAD Designer is open-source business intelligence software by Michael Thomason.");
	appendBody(@"MAD is an open-source mobile business intelligence and report-design system. A .mad file stores a report's schema snapshot, query definition, and visual layout in one compact, portable document.");
	appendBody(@"MAD Designer connects natively to MySQL / MariaDB, Microsoft SQL Server, and PostgreSQL databases, and uses SQLite for portable sample documents and local row caching.");

	appendHeading(@"Workflow");

	appendSubheading(@"1. Connect a Data Source");
	appendBody(@"Tap + in the file explorer (or click New Document on macOS) and choose a database driver. MAD reads the database schema and creates a new .mad document. Database credentials can be saved in your Keychain and are never stored inside the .mad file.");

	appendSubheading(@"2. Build the Query (MAD Query)");
	appendBody(@"Add tables, joins, filter predicates, groupings, and sort order visually, or paste a SQL SELECT statement directly. MAD generates the database-specific SQL automatically.");

	appendSubheading(@"3. Lay Out the Report (MAD Designer)");
	appendBody(@"Place data fields, static labels, aggregate functions, barcodes, and shapes across Report Header, Page Header, Group Headers and Footers, Detail, Page Footer, and Report Footer sections.");

	appendSubheading(@"4. View & Export (MAD Viewer)");
	appendBody(@"Refresh the report against live data, browse paginated output, print, or export to PDF, HTML, CSV, JSON, or plain text.");

	appendHeading(@"Supported Capabilities");

	appendSubheading(@"Database Drivers");
	appendBody(@"• SQLite 3 (local .sqlite3 / .db files and embedded row caching)\n• MySQL & MariaDB (via MariaDB Connector/C over TLS)\n• Microsoft SQL Server (via FreeTDS over TDS / TLS)\n• PostgreSQL (via PostgreSQL libpq)");

	appendSubheading(@"Report Sections & Elements");
	appendBody(@"• Parametric Bands: Report Header, Page Header, Group Header(s), Report Detail, Group Footer(s), Page Footer, and Report Footer.\n• Elements: Static Labels, Bound Data Fields, Group & Report Aggregates (SUM, COUNT, AVG, MIN, MAX, STDDEV, VARIANCE), Barcodes (powered by zint), Images, and Lines.");

	appendSubheading(@"Export Formats");
	appendBody(@"• PDF Document (.pdf), HTML Page (.html), HTML Flow (.html), CSV Spreadsheet (.csv), JSON Data (.json), JSON Full Report (.json), and Plain Text (.txt).");

	return result;
}

+ (NSAttributedString *)licensingAttributedTextFromBundle:(nullable NSBundle *)bundle {
	NSDictionary *headingAttrs = [self headingAttributes];
	NSDictionary *subheadingAttrs = [self subheadingAttributes];
	NSDictionary *bodyAttrs = [self bodyAttributes];
	NSDictionary *monoAttrs = [self monospaceLicenseAttributes];

	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

	void (^appendHeading)(NSString *) = ^(NSString *title) {
		if (result.length > 0) {
			[result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:bodyAttrs]];
		}
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n\n"] attributes:headingAttrs]];
	};

	appendHeading(@"Licensing & Product Marks Notice");
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:[[self mitLicenseAndBrandNoticeText] stringByAppendingString:@"\n\n"] attributes:bodyAttrs]];

	NSString *noticeText = [self textContentsOfResource:@"NOTICE" inDirectory:nil bundle:bundle];
	if (noticeText.length == 0) {
		noticeText =
			@"MAD (Mobile Analytics Document) — the MAD Designer and MAD Viewer apps\n"
			@"Copyright (c) 2012-2026 Michael Thomason\n\n"
			@"Licensed under the MIT License; see LICENSE.\n\n"
			@"The names \"MAD\", \"MAD Designer\", \"MAD Viewer\", and the names of related products are the author's product names and marks. "
			@"The application icons and other product artwork are the author's copyright, and all rights in them are reserved. "
			@"Neither the names nor the artwork are licensed under the MIT License, and no permission is granted to use them as the name or branding of another product, service, or distribution, or in a way that suggests endorsement by the author.\n\n"
			@"Descriptive references to .mad files, to this project, and to its software are welcome: saying that a tool reads or writes .mad files, or that it is compatible with MAD, is not a use of the names as branding.";
	}
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:@"NOTICE\n\n" attributes:subheadingAttrs]];
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:[noticeText stringByAppendingString:@"\n"] attributes:monoAttrs]];

	appendHeading(@"LGPL-3.0 Written Relink Offer (FreeTDS & MariaDB Connector/C)");
	NSString *relinkOffer =
		@"MAD Designer links FreeTDS 1.4.27 and MariaDB Connector/C 3.4.11 statically. Both libraries are licensed under LGPL-2.0-or-later and are taken here under LGPL-3.0 (for compatibility with Apache-2.0 OpenSSL 3), whose section 4 requires that a recipient be able to modify the library and relink the application.\n\n"
		@"• FreeTDS 1.4.27: One installed header (sybdb.h) is modified; the modification and its date are marked in the file itself, and the edit is made by Compressor/lib/recipes/freetds.sh. The complete corresponding source is upstream FreeTDS at https://www.freetds.org.\n"
		@"• MariaDB Connector/C 3.4.11: Linked statically as libmariadbclient.a with the caching_sha2_password and sha256_password authentication plugins compiled in. The complete corresponding source is upstream MariaDB Connector/C at https://mariadb.org.\n\n"
		@"To exercise your right to relink this application against a modified FreeTDS or MariaDB Connector/C, contact mthomason@gmail.com to receive the object files and build materials needed to do so (the pinned upstream sources in Compressor/matrix.conf and the Compressor build recipes). This offer stands for at least three years from the last distribution of the application.\n";
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:relinkOffer attributes:bodyAttrs]];

	appendHeading(@"MIT License");
	NSString *mitText = [self textContentsOfResource:@"LICENSE" inDirectory:nil bundle:bundle];
	if (mitText.length == 0) {
		mitText =
			@"MIT License\n\n"
			@"Copyright (c) 2012-2026 Michael Thomason\n\n"
			@"Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\n"
			@"The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\n"
			@"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.";
	}
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:[mitText stringByAppendingString:@"\n"] attributes:monoAttrs]];

	return result;
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)thirdPartyComponents {
	return @[
		@{
			@"name": @"SQLite",
			@"details": @"Public domain. https://sqlite.org",
			@"licenseFile": @"sqlite3-LICENSE.md",
			@"licenseTitle": @"SQLite Blessing"
		},
		@{
			@"name": @"zlib",
			@"details": @"© 1995–2026 Jean-loup Gailly and Mark Adler. Provided under the zlib License.",
			@"licenseFile": @"zlib-LICENSE.txt",
			@"licenseTitle": @"zlib License"
		},
		@{
			@"name": @"bzip2",
			@"details": @"© 1996–2019 Julian R Seward. Provided under the bzip2 License.",
			@"licenseFile": @"bzip2-LICENSE.txt",
			@"licenseTitle": @"bzip2 License"
		},
		@{
			@"name": @"libpng",
			@"details": @"© 1995–2026 The PNG Reference Library Authors, © 2018–2026 Cosmin Truta and contributors. Provided under the PNG Reference Library License version 2.",
			@"licenseFile": @"libpng-LICENSE.txt",
			@"licenseTitle": @"libpng — PNG Reference Library License v2"
		},
		@{
			@"name": @"libarchive",
			@"details": @"© 2003–2018 Tim Kientzle and contributors. Provided under the BSD 2-Clause License.",
			@"licenseFile": @"libarchive-BSD-2-Clause.txt",
			@"licenseTitle": @"libarchive — BSD 2-Clause License"
		},
		@{
			@"name": @"zint",
			@"details": @"© 2008–2025 Robin Stuart and contributors. Provided under the BSD 3-Clause License.",
			@"licenseFile": @"zint-BSD-3-Clause.txt",
			@"licenseTitle": @"zint — BSD 3-Clause License"
		},
		@{
			@"name": @"OpenSSL",
			@"details": @"© 1998–2026 The OpenSSL Project Authors. Provided under the Apache License 2.0. A copy of the license is included below.",
			@"licenseFile": @"openssl-Apache-2.0.txt",
			@"licenseTitle": @"Apache License 2.0 (OpenSSL)"
		},
		@{
			@"name": @"PostgreSQL libpq",
			@"details": @"Portions © 1996–2026 PostgreSQL Global Development Group; Portions © 1994 The Regents of the University of California. Provided under the PostgreSQL License.",
			@"licenseFile": @"postgres-LICENSE.txt",
			@"licenseTitle": @"PostgreSQL License (libpq)"
		},
		@{
			@"name": @"MariaDB Connector/C",
			@"details": @"© MariaDB Corporation Ab and contributors. This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. A copy of the license is included below, and the complete corresponding source is available at https://mariadb.org. To exercise your right to relink this application against a modified MariaDB Connector/C, contact mthomason@gmail.com to receive the object files and build materials needed to do so (available for at least three years from the last distribution of the application).",
			@"licenseFile": @"LGPL-3.0.txt",
			@"licenseTitle": @"GNU Lesser General Public License v3.0 (FreeTDS, MariaDB Connector/C)"
		},
		@{
			@"name": @"FreeTDS",
			@"details": @"© 1998–2015 Brian Bruns, Frediano Ziglio and contributors. This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. One installed header (sybdb.h) is modified as marked in the file. A copy of the license is included below, and the complete corresponding source is available at https://www.freetds.org. To exercise your right to relink this application against a modified FreeTDS, contact mthomason@gmail.com to receive the object files and build materials needed to do so (available for at least three years from the last distribution of the application).",
			@"licenseFile": @"LGPL-3.0.txt",
			@"licenseTitle": @"GNU Lesser General Public License v3.0 (FreeTDS, MariaDB Connector/C)"
		},
		@{
			@"name": @"asn1c runtime",
			@"details": @"© 2004, 2006 Lev Walkin. Redistribution and modification permitted subject to the BSD License.",
			@"licenseFile": @"asn1c-BSD.txt",
			@"licenseTitle": @"asn1c Runtime — BSD License"
		},
		@{
			@"name": @"pngquant rwpng",
			@"details": @"© 1998–2000 Greg Roelofs, © 2009–2014 Kornel Lesiński. Provided under the BSD 2-Clause License.",
			@"licenseFile": @"rwpng-BSD-2-Clause.txt",
			@"licenseTitle": @"pngquant rwpng — BSD 2-Clause License"
		},
		@{
			@"name": @"NSData+Base64",
			@"details": @"© 2009–2011 Matt Gallagher. Provided under a permissive license with copyright notice retained.",
			@"licenseFile": @"",
			@"licenseTitle": @""
		},
		@{
			@"name": @"miniz",
			@"details": @"Rich Geldreich. Released into the public domain (Unlicense).",
			@"licenseFile": @"",
			@"licenseTitle": @""
		},
		@{
			@"name": @"Font Awesome",
			@"details": @"© Dave Gandy. The font is provided under the SIL Open Font License 1.1.",
			@"licenseFile": @"FontAwesome-OFL-1.1.txt",
			@"licenseTitle": @"Font Awesome — SIL Open Font License 1.1"
		},
		@{
			@"name": @"Carbon Block",
			@"details": @"© 1999 Ray Larabie. Freeware, used under the terms accompanying the font.",
			@"licenseFile": @"CarbonBlock-Larabie-read_me.html",
			@"licenseTitle": @"Carbon Block — Ray Larabie Freeware License"
		},
	];
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)bundledLicenseFiles {
	return @[
		@{ @"title": @"GNU Lesser General Public License v3.0 (FreeTDS, MariaDB Connector/C)", @"file": @"LGPL-3.0.txt" },
		@{ @"title": @"Apache License 2.0 (OpenSSL)", @"file": @"openssl-Apache-2.0.txt" },
		@{ @"title": @"libarchive — BSD 2-Clause License", @"file": @"libarchive-BSD-2-Clause.txt" },
		@{ @"title": @"zint — BSD 3-Clause License", @"file": @"zint-BSD-3-Clause.txt" },
		@{ @"title": @"PostgreSQL License (libpq)", @"file": @"postgres-LICENSE.txt" },
		@{ @"title": @"libpng — PNG Reference Library License v2", @"file": @"libpng-LICENSE.txt" },
		@{ @"title": @"bzip2 License", @"file": @"bzip2-LICENSE.txt" },
		@{ @"title": @"zlib License", @"file": @"zlib-LICENSE.txt" },
		@{ @"title": @"SQLite Blessing", @"file": @"sqlite3-LICENSE.md" },
		@{ @"title": @"asn1c Runtime — BSD License", @"file": @"asn1c-BSD.txt" },
		@{ @"title": @"pngquant rwpng — BSD 2-Clause License", @"file": @"rwpng-BSD-2-Clause.txt" },
		@{ @"title": @"Font Awesome — SIL Open Font License 1.1", @"file": @"FontAwesome-OFL-1.1.txt" },
	];
}

+ (NSAttributedString *)acknowledgementsAttributedText {
	return [self acknowledgementsAttributedTextFromBundle:nil];
}

+ (NSAttributedString *)acknowledgementsAttributedTextFromBundle:(nullable NSBundle *)bundle {
	NSDictionary *headingAttrs = [self headingAttributes];
	NSDictionary *componentTitleAttrs = [self subheadingAttributes];
	NSDictionary *bodyAttrs = [self bodyAttributes];
	NSDictionary *licenseBodyAttrs = [self monospaceLicenseAttributes];

	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

	void (^appendSectionHeading)(NSString *) = ^(NSString *title) {
		if (result.length > 0) {
			[result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:bodyAttrs]];
		}
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n\n"] attributes:headingAttrs]];
	};

	void (^appendComponent)(NSString *, NSString *) = ^(NSString *name, NSString *details) {
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:componentTitleAttrs]];
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:@" — " attributes:bodyAttrs]];
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[details stringByAppendingString:@"\n\n"] attributes:bodyAttrs]];
	};

	appendSectionHeading(NSLocalizedString(@"Open Source Components", @"Open Source Components"));

	[result appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"This application includes the following open source software:\n\n", @"Acknowledgements intro") attributes:bodyAttrs]];

	for (NSDictionary<NSString *, NSString *> *comp in [self thirdPartyComponents]) {
		appendComponent(comp[@"name"] ?: @"", comp[@"details"] ?: @"");
	}

	BOOL addedLicenseSectionHeader = NO;
	for (NSDictionary<NSString *, NSString *> *entry in [self bundledLicenseFiles]) {
		NSString *filename = entry[@"file"] ?: @"";
		NSString *title = entry[@"title"] ?: @"";
		NSString *contents = [self textContentsOfResource:filename inDirectory:@"Licenses" bundle:bundle];
		if (contents == nil || contents.length == 0) {
			continue;
		}
		if (!addedLicenseSectionHeader) {
			appendSectionHeading(NSLocalizedString(@"License Texts", @"License Texts"));
			addedLicenseSectionHeader = YES;
		}
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[title stringByAppendingString:@"\n\n"] attributes:componentTitleAttrs]];
		[result appendAttributedString:[[NSAttributedString alloc] initWithString:[contents stringByAppendingString:@"\n\n"] attributes:licenseBodyAttrs]];
	}

	return result;
}

+ (NSAttributedString *)attributedTextForSingleComponent:(NSDictionary<NSString *, NSString *> *)comp
												  bundle:(nullable NSBundle *)bundle {
	NSDictionary *headingAttrs = [self headingAttributes];
	NSDictionary *componentTitleAttrs = [self subheadingAttributes];
	NSDictionary *bodyAttrs = [self bodyAttributes];
	NSDictionary *licenseBodyAttrs = [self monospaceLicenseAttributes];

	NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
	NSString *compName = comp[@"name"] ?: @"";
	NSString *compDetails = comp[@"details"] ?: @"";
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:[compName stringByAppendingString:@"\n\n"] attributes:headingAttrs]];
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:[compDetails stringByAppendingString:@"\n\n"] attributes:bodyAttrs]];

	NSString *licenseFile = comp[@"licenseFile"] ?: @"";
	NSString *licenseTitle = comp[@"licenseTitle"] ?: @"";
	if (licenseFile.length > 0) {
		NSString *contents = [self textContentsOfResource:licenseFile inDirectory:@"Licenses" bundle:bundle];
		if (contents != nil && contents.length > 0) {
			if (licenseTitle.length > 0) {
				[result appendAttributedString:[[NSAttributedString alloc] initWithString:[licenseTitle stringByAppendingString:@"\n\n"] attributes:componentTitleAttrs]];
			}
			[result appendAttributedString:[[NSAttributedString alloc] initWithString:[contents stringByAppendingString:@"\n"] attributes:licenseBodyAttrs]];
		}
	}
	return result;
}

#pragma mark - Lifecycle

- (instancetype)init {
	return [self initWithBundle:nil];
}

- (instancetype)initWithBundle:(nullable NSBundle *)bundle {
	NSRect frame = NSMakeRect(0, 0, 760, 620);
	NSWindowStyleMask style = NSWindowStyleMaskTitled
		| NSWindowStyleMaskClosable
		| NSWindowStyleMaskMiniaturizable
		| NSWindowStyleMaskResizable;
	NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
												   styleMask:style
													 backing:NSBackingStoreBuffered
													   defer:NO];
	window.title = @"About MAD Designer";
	window.minSize = NSMakeSize(640, 480);
	window.releasedWhenClosed = NO;
	[window center];

	if (self = [super initWithWindow:window]) {
		_resourceBundle = [MADMacAboutWindowController resolvedBundle:bundle];
		[self buildInterface];
		[self switchToTab:MADMacAboutTabOverview];
	}
	return self;
}

#pragma mark - Interface Construction

- (NSScrollView *)makeScrollingTextView:(NSTextView * __strong *)outTextView frame:(NSRect)frame {
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
	scrollView.hasVerticalScroller = YES;
	scrollView.hasHorizontalScroller = NO;
	scrollView.autohidesScrollers = YES;
	scrollView.borderType = NSBezelBorder;
	scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	NSSize contentSize = scrollView.contentSize;
	NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	textView.minSize = NSMakeSize(0.0, contentSize.height);
	textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
	textView.verticallyResizable = YES;
	textView.horizontallyResizable = NO;
	textView.autoresizingMask = NSViewWidthSizable;
	textView.textContainer.containerSize = NSMakeSize(contentSize.width, FLT_MAX);
	textView.textContainer.widthTracksTextView = YES;
	textView.editable = NO;
	textView.selectable = YES;
	textView.richText = YES;
	textView.importsGraphics = NO;
	textView.textContainerInset = NSMakeSize(16.0, 14.0);
	textView.backgroundColor = [NSColor textBackgroundColor];

	scrollView.documentView = textView;
	if (outTextView != NULL) {
		*outTextView = textView;
	}
	return scrollView;
}

- (void)buildInterface {
	NSView *content = self.window.contentView;
	NSRect bounds = content.bounds;

	// 1. Top Header Banner (138pt height)
	CGFloat headerHeight = 138.0;
	NSView *headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, NSHeight(bounds) - headerHeight, NSWidth(bounds), headerHeight)];
	headerView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[content addSubview:headerView];

	_appIconImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(24, headerHeight - 92, 72, 72)];
	_appIconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
	NSString *iconPath = [_resourceBundle pathForResource:@"AppIcon" ofType:@"png"];
	NSImage *iconImage = iconPath.length > 0 ? [[NSImage alloc] initWithContentsOfFile:iconPath] : [NSApp applicationIconImage];
	_appIconImageView.image = iconImage;
	_appIconImageView.wantsLayer = YES;
	_appIconImageView.layer.cornerRadius = 16.0;
	_appIconImageView.layer.masksToBounds = YES;
	[headerView addSubview:_appIconImageView];

	NSString *displayName = [MADMacAboutWindowController bundleDisplayNameForBundle:_resourceBundle];
	_titleLabel = [NSTextField labelWithString:displayName];
	_titleLabel.frame = NSMakeRect(112, headerHeight - 40, 380, 26);
	_titleLabel.font = [NSFont boldSystemFontOfSize:21.0];
	_titleLabel.textColor = [NSColor colorWithSRGBRed:0.80 green:0.16 blue:0.18 alpha:1.0];
	[headerView addSubview:_titleLabel];

	NSString *versionStr = [MADMacAboutWindowController versionTextForBundle:_resourceBundle];
	NSString *buildStr = [MADMacAboutWindowController buildTextForBundle:_resourceBundle];
	_versionLabel = [NSTextField labelWithString:[NSString stringWithFormat:@"%@ (%@)", versionStr, buildStr]];
	_versionLabel.frame = NSMakeRect(112, headerHeight - 60, 380, 18);
	_versionLabel.font = [NSFont monospacedDigitSystemFontOfSize:12.5 weight:NSFontWeightMedium];
	_versionLabel.textColor = [NSColor labelColor];
	[headerView addSubview:_versionLabel];

	_subtitleLabel = [NSTextField labelWithString:@"MAD Designer is open-source business intelligence software by Michael Thomason."];
	_subtitleLabel.frame = NSMakeRect(112, headerHeight - 80, NSWidth(bounds) - 136, 18);
	_subtitleLabel.autoresizingMask = NSViewWidthSizable;
	_subtitleLabel.font = [NSFont systemFontOfSize:12.5];
	_subtitleLabel.textColor = [NSColor labelColor];
	[headerView addSubview:_subtitleLabel];

	_copyrightLabel = [NSTextField labelWithString:[MADMacAboutWindowController humanReadableCopyrightForBundle:_resourceBundle]];
	_copyrightLabel.frame = NSMakeRect(112, headerHeight - 98, NSWidth(bounds) - 136, 16);
	_copyrightLabel.autoresizingMask = NSViewWidthSizable;
	_copyrightLabel.font = [NSFont systemFontOfSize:11.5];
	_copyrightLabel.textColor = [NSColor secondaryLabelColor];
	[headerView addSubview:_copyrightLabel];

	_licenseSummaryLabel = [NSTextField wrappingLabelWithString:[MADMacAboutWindowController mitLicenseAndBrandNoticeText]];
	_licenseSummaryLabel.frame = NSMakeRect(24, 8, NSWidth(bounds) - 48, 32);
	_licenseSummaryLabel.autoresizingMask = NSViewWidthSizable;
	_licenseSummaryLabel.font = [NSFont systemFontOfSize:11.0];
	_licenseSummaryLabel.textColor = [NSColor secondaryLabelColor];
	[headerView addSubview:_licenseSummaryLabel];

	_gitHubButton = [NSButton buttonWithTitle:@"Source Code on GitHub"
									   target:self
									   action:@selector(openGitHubAction:)];
	_gitHubButton.bezelStyle = NSBezelStyleRounded;
	_gitHubButton.frame = NSMakeRect(NSWidth(bounds) - 196, headerHeight - 44, 172, 28);
	_gitHubButton.autoresizingMask = NSViewMinXMargin;
	[headerView addSubview:_gitHubButton];

	NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(0, NSHeight(bounds) - headerHeight - 1, NSWidth(bounds), 1)];
	divider.boxType = NSBoxSeparator;
	divider.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
	[content addSubview:divider];

	// 2. Segmented Tab Bar
	CGFloat segBarY = NSHeight(bounds) - headerHeight - 42.0;
	_sectionSegmentedControl = [NSSegmentedControl segmentedControlWithLabels:@[
		@"Overview",
		@"License & Notice",
		@"Acknowledgements"
	] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(sectionSegmentedControlChanged:)];
	_sectionSegmentedControl.frame = NSMakeRect((NSWidth(bounds) - 420.0) * 0.5, segBarY + 6.0, 420.0, 28.0);
	_sectionSegmentedControl.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin;
	_sectionSegmentedControl.segmentDistribution = NSSegmentDistributionFillEqually;
	[content addSubview:_sectionSegmentedControl];

	// 3. Content Tab View
	NSRect tabFrame = NSMakeRect(20, 16, NSWidth(bounds) - 40, segBarY - 20);
	_contentTabView = [[NSTabView alloc] initWithFrame:tabFrame];
	_contentTabView.tabViewType = NSNoTabsNoBorder;
	_contentTabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[content addSubview:_contentTabView];

	// Tab 0: Overview
	NSTabViewItem *overviewItem = [[NSTabViewItem alloc] initWithIdentifier:@"overview"];
	NSTextView *overviewTV = nil;
	NSScrollView *overviewScroll = [self makeScrollingTextView:&overviewTV frame:_contentTabView.bounds];
	_overviewTextView = overviewTV;
	[_overviewTextView.textStorage setAttributedString:[MADMacAboutWindowController overviewAttributedText]];
	overviewItem.view = overviewScroll;
	[_contentTabView addTabViewItem:overviewItem];

	// Tab 1: License & Notice
	NSTabViewItem *licenseItem = [[NSTabViewItem alloc] initWithIdentifier:@"licensing"];
	NSTextView *licenseTV = nil;
	NSScrollView *licenseScroll = [self makeScrollingTextView:&licenseTV frame:_contentTabView.bounds];
	_licensingTextView = licenseTV;
	[_licensingTextView.textStorage setAttributedString:[MADMacAboutWindowController licensingAttributedTextFromBundle:_resourceBundle]];
	licenseItem.view = licenseScroll;
	[_contentTabView addTabViewItem:licenseItem];

	// Tab 2: Acknowledgements (Split view: Left component list, Right full attributions & license texts)
	NSTabViewItem *ackItem = [[NSTabViewItem alloc] initWithIdentifier:@"acknowledgements"];
	_acknowledgementsSplitView = [[NSSplitView alloc] initWithFrame:_contentTabView.bounds];
	_acknowledgementsSplitView.vertical = YES;
	_acknowledgementsSplitView.dividerStyle = NSSplitViewDividerStyleThin;
	_acknowledgementsSplitView.delegate = self;
	_acknowledgementsSplitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	NSScrollView *sidebarScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 210, NSHeight(_contentTabView.bounds))];
	sidebarScroll.hasVerticalScroller = YES;
	sidebarScroll.autohidesScrollers = YES;
	sidebarScroll.borderType = NSBezelBorder;
	sidebarScroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	_componentTableView = [[NSTableView alloc] initWithFrame:sidebarScroll.bounds];
	_componentTableView.headerView = nil;
	_componentTableView.rowHeight = 24.0;
	_componentTableView.allowsEmptySelection = NO;
	_componentTableView.dataSource = self;
	_componentTableView.delegate = self;
	NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"ComponentColumn"];
	col.width = 190.0;
	[_componentTableView addTableColumn:col];
	sidebarScroll.documentView = _componentTableView;

	NSTextView *ackTV = nil;
	NSScrollView *ackScroll = [self makeScrollingTextView:&ackTV
													frame:NSMakeRect(211, 0, NSWidth(_contentTabView.bounds) - 211, NSHeight(_contentTabView.bounds))];
	_acknowledgementsTextView = ackTV;
	[_acknowledgementsTextView.textStorage setAttributedString:[MADMacAboutWindowController acknowledgementsAttributedTextFromBundle:_resourceBundle]];

	[_acknowledgementsSplitView addSubview:sidebarScroll];
	[_acknowledgementsSplitView addSubview:ackScroll];
	[_acknowledgementsSplitView setPosition:210.0 ofDividerAtIndex:0];

	ackItem.view = _acknowledgementsSplitView;
	[_contentTabView addTabViewItem:ackItem];

	[_componentTableView reloadData];
	[_componentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

#pragma mark - Navigation & Actions

- (void)switchToTab:(MADMacAboutTab)tab {
	_selectedTab = tab;
	_sectionSegmentedControl.selectedSegment = tab;
	[_contentTabView selectTabViewItemAtIndex:tab];
}

- (void)sectionSegmentedControlChanged:(NSSegmentedControl *)sender {
	[self switchToTab:(MADMacAboutTab)sender.selectedSegment];
}

- (void)selectComponentAtIndex:(NSInteger)index {
	NSInteger rowCount = [self numberOfRowsInTableView:_componentTableView];
	if (index < 0 || index >= rowCount) {
		return;
	}
	[_componentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)index] byExtendingSelection:NO];
	[self updateAcknowledgementsForSelectedRow:index];
}

- (void)updateAcknowledgementsForSelectedRow:(NSInteger)row {
	if (row <= 0) {
		[_acknowledgementsTextView.textStorage setAttributedString:
			[MADMacAboutWindowController acknowledgementsAttributedTextFromBundle:_resourceBundle]];
	} else {
		NSArray<NSDictionary<NSString *, NSString *> *> *components = [MADMacAboutWindowController thirdPartyComponents];
		NSInteger compIndex = row - 1;
		if (compIndex >= 0 && (NSUInteger)compIndex < components.count) {
			[_acknowledgementsTextView.textStorage setAttributedString:
				[MADMacAboutWindowController attributedTextForSingleComponent:components[(NSUInteger)compIndex]
																	   bundle:_resourceBundle]];
		}
	}
	[_acknowledgementsTextView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void)openGitHubAction:(nullable id) __unused sender {
	NSURL *url = [NSURL URLWithString:kMADGitHubRepositoryURL];
	if (url != nil) {
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
}

#pragma mark - NSTableViewDataSource & NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *) __unused tableView {
	return (NSInteger)[MADMacAboutWindowController thirdPartyComponents].count + 1;
}

- (nullable NSView *)tableView:(NSTableView *)tableView
			viewForTableColumn:(nullable NSTableColumn *) __unused tableColumn
						   row:(NSInteger)row {
	NSTextField *cell = [tableView makeViewWithIdentifier:@"ComponentCell" owner:self];
	if (cell == nil) {
		cell = [NSTextField labelWithString:@""];
		cell.identifier = @"ComponentCell";
		cell.lineBreakMode = NSLineBreakByTruncatingTail;
	}
	if (row == 0) {
		cell.stringValue = @"All Components & Licenses";
		cell.font = [NSFont boldSystemFontOfSize:12.0];
	} else {
		NSArray<NSDictionary<NSString *, NSString *> *> *components = [MADMacAboutWindowController thirdPartyComponents];
		cell.stringValue = components[(NSUInteger)(row - 1)][@"name"] ?: @"";
		cell.font = [NSFont systemFontOfSize:12.0];
	}
	return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *) __unused notification {
	[self updateAcknowledgementsForSelectedRow:_componentTableView.selectedRow];
}

#pragma mark - NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *) __unused splitView
constrainMinCoordinate:(CGFloat) __unused proposedMinimumPosition
		 ofSubviewAt:(NSInteger) __unused dividerIndex {
	return 160.0;
}

- (CGFloat)splitView:(NSSplitView *) __unused splitView
constrainMaxCoordinate:(CGFloat) __unused proposedMaximumPosition
		 ofSubviewAt:(NSInteger) __unused dividerIndex {
	return 280.0;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
	if (splitView.subviews.count > 0 && view == splitView.subviews.firstObject) {
		return NO;
	}
	return YES;
}

@end
