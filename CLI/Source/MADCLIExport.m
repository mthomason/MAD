//
//  MADCLIExport.m
//  MAD Designer
//
//  `mad export` -- render the report and write it out.  PDF is the only format that
//  exists today; MAD_CLI.md section 5.3 asks for a protocol so JSON and CSV are new
//  classes rather than new arms of a switch, and that is the shape this will take.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MADFoundation/MADCredential.h>

MADCLIExitCode MADCLIRunExport(MADCLIInvocation *invocation) {

	NSString *format = invocation.format.length > 0 ? invocation.format.lowercaseString : @"pdf";
	if (![format isEqualToString: @"pdf"]) {
		MADCLIError(@"export: --format %@ is not supported yet; the only format is pdf.", invocation.format);
		return MADCLIExitUsage;
	}
	if (invocation.outPath.length == 0) {
		MADCLIError(@"export: --out is required.");
		return MADCLIExitUsage;
	}

	NSURL *outURL = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(invocation.outPath)];

	// CGPDFContext will not create the directory, and it fails in a way that reads as
	// a rendering fault rather than a missing path, so make it here.
	NSError *directoryError = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtURL: [outURL URLByDeletingLastPathComponent]
								  withIntermediateDirectories: YES
												   attributes: nil
														error: &directoryError]) {
		MADCLIError(@"export: cannot create %@: %@", [outURL URLByDeletingLastPathComponent].path,
					directoryError.localizedDescription);
		return MADCLIExitUsage;
	}

	NSError *error = nil;
	MADCLIVerbose(invocation, @"Opening %@", invocation.documentURL.lastPathComponent);
	MADCLIDocument *cliDocument = [MADCLIDocument documentWithURL: invocation.documentURL error: &error];
	if (cliDocument == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		return MADCLIExitBadDocument;
	}

	// The cache is derived and lives outside the document, so a fresh checkout has
	// none.  Export needs the row data, which means a refresh first.  A spawned CLI
	// cannot see the keychain items the app stored (different access group), so the
	// credentials come from --credentials, the way the refresh verb takes them.
	MADCredential *credentials = nil;
	if (invocation.credentials.length > 0) {
		NSRange colon = [invocation.credentials rangeOfString: @":"];
		if (colon.location == NSNotFound) {
			MADCLIError(@"--credentials wants user:password.");
			return MADCLIExitUsage;
		}
		credentials = [[MADCredential alloc]
					   initWithUsername: [invocation.credentials substringToIndex: colon.location]
						   andPassword: [invocation.credentials substringFromIndex: colon.location + 1]];
	}
	MADCLIVerbose(invocation, @"Refreshing");
	if (![cliDocument refreshWithCredentials: credentials error: &error]) {
		MADCLIError(@"refresh failed: %@", MADCLIDescriptionForError(error));
		return MADCLIExitQueryFailed;
	}

	MADCLIVerbose(invocation, @"Rendering to %@", outURL.path);
	if (![cliDocument writePDFToURL: outURL deterministic: invocation.deterministic error: &error]) {
		MADCLIError(@"export failed: %@", MADCLIDescriptionForError(error));
		return MADCLIExitExportFailed;
	}

	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: outURL.path error: NULL];
	MADCLILog(invocation, @"wrote %@ (%@ bytes, %lu pages)", outURL.path,
			  attributes[NSFileSize] ?: @"?", (unsigned long)cliDocument.pageCount);

	return MADCLIExitSuccess;
}
