//
//  MADCLIRefresh.m
//  MAD Designer
//
//  `mad refresh` -- the data path.  The verb the rest depends on.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADocument.h>
#import <MADFoundation/MADCredential.h>

MADCLIExitCode MADCLIRunRefresh(MADCLIInvocation *invocation) {

	if (invocation.rows > 0) {
		MADCLIError(@"--rows is not implemented yet.");
		return MADCLIExitUsage;
	}

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
		MADCLIError(@"%@", error.localizedDescription);
		return MADCLIExitBadDocument;
	}

	MADCLIVerbose(invocation, @"Refreshing");
	NSDate *started = [NSDate date];
	if (![cliDocument refreshWithCredentials: credentials error: &error]) {
		MADCLIError(@"refresh failed: %@", error.localizedDescription);
		return MADCLIExitQueryFailed;
	}
	NSTimeInterval elapsed = -[started timeIntervalSinceNow];

	NSUInteger rows = cliDocument.document.numberOfResults;
	MADCLILog(invocation, @"refreshed %lu rows in %.2f s", (unsigned long)rows, elapsed);
	MADCLIVerbose(invocation, @"cache %@", cliDocument.document.urlDataTableCache.path);

	return MADCLIExitSuccess;
}
