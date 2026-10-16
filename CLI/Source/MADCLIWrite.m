//
//  MADCLIWrite.m
//  MAD Designer
//
//  `mad write` -- write the document out as a .mad.  It writes a *copy*: the guts
//  directory the document was read into, archived again with the v1 header, so this
//  is not a verb that edits a document (MAD_CLI.md section 1).  What it is for is the
//  byte-identity requirement: `--reproducible` pins the archive's inputs, so the same
//  document written on two platforms must compare equal (BUGS.md, that entry).
//
//  The document is opened headlessly on both platforms -- MADHeadlessDocument, not
//  the app's MADocument -- so the two sides of that comparison run the same writer
//  rather than each platform's own save.
//

#import "MADCLI.h"

#import <MAD/MADConstants.h>
#import <MAD/MADHeadlessDocument.h>

MADCLIExitCode MADCLIRunWrite(MADCLIInvocation *invocation) {

	if (invocation.outPath.length == 0) {
		MADCLIError(@"write: --out is required.");
		return MADCLIExitUsage;
	}

	NSError *error = nil;
	MADCLIVerbose(invocation, @"Opening %@", invocation.documentURL.lastPathComponent);
	MADHeadlessDocument *document = [MADHeadlessDocument documentWithContentsOfURL: invocation.documentURL
																			 error: &error];
	if (document == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		return MADCLIExitBadDocument;
	}

	NSURL *outURL = [NSURL fileURLWithPath: MADCLIResolveArgumentPath(invocation.outPath)];
	NSError *directoryError = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtURL: [outURL URLByDeletingLastPathComponent]
								 withIntermediateDirectories: YES
												  attributes: nil
													   error: &directoryError]) {
		MADCLIError(@"write: cannot create %@: %@", [outURL URLByDeletingLastPathComponent].path,
					directoryError.localizedDescription);
		return MADCLIExitUsage;
	}

	MADCLIVerbose(invocation, @"Writing %@%@", outURL.path, invocation.reproducible ? @" (reproducible)" : @"");
	if (![document writeToURL: outURL reproducible: invocation.reproducible error: &error]) {
		MADCLIError(@"write failed: %@", MADCLIDescriptionForError(error));
		return MADCLIExitExportFailed;
	}

	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: outURL.path error: NULL];
	MADCLILog(invocation, @"wrote %@ (%@ bytes%@)", outURL.path, attributes[NSFileSize] ?: @"?",
			  invocation.reproducible ? @", reproducible" : @"");

	return MADCLIExitSuccess;
}
