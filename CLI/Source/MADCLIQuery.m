//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIQuery.m
//  MAD Designer
//
//  `mad query` -- print the SQL the document's query generates, without running it.
//  This is the feature the application is built around: the user assembles tables,
//  joins and filters, and the software writes the SQL.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADQueryFull.h>

MADCLIExitCode MADCLIRunQuery(MADCLIInvocation *invocation) {

	NSError *error = nil;
	MADCLIDocument *cliDocument = [MADCLIDocument documentWithURL: invocation.documentURL error: &error];
	if (cliDocument == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		return MADCLIExitBadDocument;
	}

	NSError *sqlError = nil;
	NSString *sql = [cliDocument.document.mainQuery
					 copySQLWithManagedObjectContext: cliDocument.document.storeContext
											   error: &sqlError];
	if (sql == nil) {
		MADCLIError(@"the document's query produced no SQL: %@", MADCLIDescriptionForError(sqlError));
		return MADCLIExitQueryFailed;
	}

	printf("%s\n", sql.UTF8String);
	return MADCLIExitSuccess;
}
