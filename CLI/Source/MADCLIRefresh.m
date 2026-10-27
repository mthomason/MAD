//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIRefresh.m
//  MAD Designer
//
//  `mad refresh` -- the data path.  The verb the rest depends on.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADQueryFull.h>
#import <MADFoundation/MADCredential.h>

MADCLIExitCode MADCLIRunRefresh(MADCLIInvocation *invocation) {

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

	NSError *error = nil;
	MADCLIVerbose(invocation, @"Opening %@", invocation.documentURL.lastPathComponent);
	MADCLIDocument *cliDocument = [MADCLIDocument documentWithURL: invocation.documentURL error: &error];
	if (cliDocument == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		return MADCLIExitBadDocument;
	}

	NSError *overrideError = nil;
	if (!MADCLIApplyConnectionOverrides(invocation, cliDocument.document, &overrideError)) {
		MADCLIError(@"%@", MADCLIDescriptionForError(overrideError));
		return MADCLIExitUsage;
	}

	// --rows caps the query, not the fetch.  The document builds its main query lazily
	// and once, with the design-mode cap (50) or no cap at all; the CLI then overwrites
	// that with the requested figure before the refresh runs, so the SQL carries a real
	// LIMIT rather than fetching everything and discarding the surplus.
	if (invocation.rows > 0) {
		cliDocument.document.mainQuery.limitResults = (NSUInteger)invocation.rows;
	}

	MADCLIVerbose(invocation, @"Refreshing");
	NSDate *started = [NSDate date];
	if (![cliDocument refreshWithCredentials: credentials error: &error]) {
		MADCLIError(@"refresh failed: %@", MADCLIDescriptionForError(error));
		return MADCLIExitQueryFailed;
	}
	NSTimeInterval elapsed = -[started timeIntervalSinceNow];

	NSUInteger rows = cliDocument.document.numberOfResults;
	MADCLILog(invocation, @"refreshed %lu rows in %.2f s", (unsigned long)rows, elapsed);
	MADCLIVerbose(invocation, @"cache %@", cliDocument.document.urlDataTableCache.path);

	return MADCLIExitSuccess;
}
