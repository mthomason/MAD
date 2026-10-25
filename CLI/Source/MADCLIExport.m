//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIExport.m
//  MAD Designer
//
//  `mad export` -- render the report and write it out.  The formats are the export
//  seam's (MADReportExporterRegistry, docs/project/MAD_CLI.md section 5.3): the verb looks one up
//  by name and hands it the document, so a new format is a new class and nothing
//  here changes.  There are no local arms left: `pdf` moved onto the seam with the
//  HTML formats (docs/project/MAD_LINUX.md section 9 Phase E), and the verb is the same for it as
//  for the rest -- the registry says whether this build can produce it.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADReportExporting.h>
#import <MAD/MADReportExporterRegistry.h>

#import <MADFoundation/MADCredential.h>

// Opens the document and refreshes it: every format needs the rows, which are
// derived and live outside the document (docs/project/MAD_FORMAT.md section 5).  A spawned CLI
// cannot see the keychain items the app stored (different access group), so the
// credentials come from --credentials, the way the refresh verb takes them.
static MADCLIDocument *MADCLIOpenRefreshedDocument(MADCLIInvocation *invocation, MADCLIExitCode *exitCode) {

	NSError *error = nil;
	MADCLIDocument *cliDocument = [MADCLIDocument documentWithURL: invocation.documentURL error: &error];
	if (cliDocument == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		*exitCode = MADCLIExitBadDocument;
		return nil;
	}

	MADCredential *credentials = nil;
	if (invocation.credentials.length > 0) {
		NSRange colon = [invocation.credentials rangeOfString: @":"];
		if (colon.location == NSNotFound) {
			MADCLIError(@"--credentials wants user:password.");
			*exitCode = MADCLIExitUsage;
			return nil;
		}
		credentials = [[MADCredential alloc]
					   initWithUsername: [invocation.credentials substringToIndex: colon.location]
						   andPassword: [invocation.credentials substringFromIndex: colon.location + 1]];
	}

	MADCLIVerbose(invocation, @"Refreshing");
	if (![cliDocument refreshWithCredentials: credentials error: &error]) {
		MADCLIError(@"refresh failed: %@", MADCLIDescriptionForError(error));
		*exitCode = MADCLIExitQueryFailed;
		return nil;
	}

	return cliDocument;
}

// The --out path, or nil for the standard output.  "-" is the convention the other
// command-line tools use and docs/project/MAD_CLI.md's default says stdout, so both spell it.
static NSURL *MADCLIExportOutputURL(MADCLIInvocation *invocation) {
	if (invocation.outPath.length == 0 || [invocation.outPath isEqualToString: @"-"]) {
		return nil;
	}
	return [NSURL fileURLWithPath: MADCLIResolveArgumentPath(invocation.outPath)];
}

// A writer that opens its own output does not create the directory, and it fails in a
// way that reads as a rendering fault rather than a missing path, so make it here.
static BOOL MADCLIExportPrepareDirectory(NSURL *outURL) {
	if (outURL == nil) return YES;
	NSError *directoryError = nil;
	if ([[NSFileManager defaultManager] createDirectoryAtURL: [outURL URLByDeletingLastPathComponent]
								 withIntermediateDirectories: YES
												  attributes: nil
													   error: &directoryError]) {
		return YES;
	}
	MADCLIError(@"export: cannot create %@: %@", [outURL URLByDeletingLastPathComponent].path,
				directoryError.localizedDescription);
	return NO;
}

MADCLIExitCode MADCLIRunExport(MADCLIInvocation *invocation) {

	NSString *format = invocation.format.length > 0 ? invocation.format.lowercaseString : @"pdf";

	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: format];
	if (exporterClass == Nil) {
		MADCLIError(@"export: --format %@ is not a format this build has; it has %@.",
					format, [[MADReportExporterRegistry registeredFormatNames] componentsJoinedByString: @", "]);
		return MADCLIExitUsage;
	}

	if (![exporterClass isAvailable]) {
		MADCLIError(@"export: --format %@ is not available in this build: %@",
					format, [exporterClass unavailableReason] ?: @"no reason given");
		return MADCLIExitExportFailed;
	}

	NSURL *outURL = MADCLIExportOutputURL(invocation);
	if ([exporterClass requiresOutputPath] && outURL == nil) {
		MADCLIError(@"export: --format %@ needs --out.", format);
		return MADCLIExitUsage;
	}
	if (!MADCLIExportPrepareDirectory(outURL)) {
		return MADCLIExitUsage;
	}

	MADCLIExitCode exitCode = MADCLIExitSuccess;
	MADCLIVerbose(invocation, @"Opening %@", invocation.documentURL.lastPathComponent);
	MADCLIDocument *cliDocument = MADCLIOpenRefreshedDocument(invocation, &exitCode);
	if (cliDocument == nil) {
		return exitCode;
	}

	MADCLIVerbose(invocation, @"Writing %@ to %@", format, outURL.path ?: @"the standard output");
	// The protocol-qualified Class does not carry NSObject's factory methods, so the
	// plain Class spelling does the allocation (the driver registry's callers do the
	// same).
	id <MADReportExporting> exporter = [[(Class)exporterClass alloc] init];
	NSError *error = nil;
	if (![exporter exportDocument: cliDocument.document
							toURL: outURL
						  options: invocation.deterministic ? MADReportExportOptionsDeterministic : MADReportExportOptionsNone
							error: &error]) {
		MADCLIError(@"export failed: %@", MADCLIDescriptionForError(error));
		return MADCLIExitExportFailed;
	}

	if (outURL != nil) {
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: outURL.path error: NULL];
		MADCLILog(invocation, @"wrote %@ (%@ bytes)", outURL.path, attributes[NSFileSize] ?: @"?");
	}

	return MADCLIExitSuccess;
}
