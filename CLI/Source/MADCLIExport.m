//
//  MADCLIExport.m
//  MAD Designer
//
//  `mad export` -- render the report and write it out.  The formats are the export
//  seam's (MADReportExporterRegistry, MAD_CLI.md section 5.3): the verb looks one up
//  by name and hands it the document, so a new format is a new class and nothing
//  here changes.  PDF is the one arm that is still local -- it is a UIKit renderer
//  drawn from the CLI's own document class, and its move onto the seam waits for the
//  render-half protocol the HTML step needs (MAD_LINUX.md section 9 Phase E).
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADReportExporting.h>
#import <MAD/MADReportExporterRegistry.h>

#import <MADFoundation/MADCredential.h>

static MADCLIExitCode MADCLIRunExportPDF(MADCLIInvocation *invocation);

// Opens the document and refreshes it: every format needs the rows, which are
// derived and live outside the document (MAD_FORMAT.md section 5).  A spawned CLI
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
// command-line tools use and MAD_CLI.md's default says stdout, so both spell it.
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

	if ([format isEqualToString: @"pdf"]) {
		return MADCLIRunExportPDF(invocation);
	}

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

#pragma mark - PDF, the local arm

MADCLIExitCode MADCLIRunExportPDF(MADCLIInvocation *invocation) {

	if (invocation.outPath.length == 0) {
		MADCLIError(@"export: --out is required for pdf.");
		return MADCLIExitUsage;
	}

#if !__APPLE__
	// PDF is a Core Graphics context drawn by a UIPrintPageRenderer; neither exists
	// off Apple, and the renderer decision (cairo/libharu, HTML/SVG first, or
	// macOS-side workers) is Phase E's to take (MAD_LINUX.md §5.2).  Saying so is
	// better than refreshing data for a page that cannot be drawn.
	MADCLIError(@"export: --format pdf is not available in this build; the renderer is Apple-only (MAD_LINUX.md §5.2).");
	return MADCLIExitExportFailed;
#else

	NSURL *outURL = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(invocation.outPath)];
	if (!MADCLIExportPrepareDirectory(outURL)) {
		return MADCLIExitUsage;
	}

	MADCLIExitCode exitCode = MADCLIExitSuccess;
	MADCLIVerbose(invocation, @"Opening %@", invocation.documentURL.lastPathComponent);
	MADCLIDocument *cliDocument = MADCLIOpenRefreshedDocument(invocation, &exitCode);
	if (cliDocument == nil) {
		return exitCode;
	}

	MADCLIVerbose(invocation, @"Rendering to %@", outURL.path);
	NSError *error = nil;
	if (![cliDocument writePDFToURL: outURL deterministic: invocation.deterministic error: &error]) {
		MADCLIError(@"export failed: %@", MADCLIDescriptionForError(error));
		return MADCLIExitExportFailed;
	}

	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: outURL.path error: NULL];
	MADCLILog(invocation, @"wrote %@ (%@ bytes, %lu pages)", outURL.path,
			  attributes[NSFileSize] ?: @"?", (unsigned long)cliDocument.pageCount);

	return MADCLIExitSuccess;
#endif
}
