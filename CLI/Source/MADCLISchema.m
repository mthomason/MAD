//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLISchema.m
//  MAD Designer
//
//  `mad schema` -- print the database schema the document was built against.  This
//  is the snapshot stored at creation time: the tables and their fields, read out of
//  the store's own Rptq entities.  It is not a live read of the source database, so
//  it works offline and needs no credentials.
//

#import "MADCLI.h"
#import "MADCLIDocument.h"

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

MADCLIExitCode MADCLIRunSchema(MADCLIInvocation *invocation) {

	NSError *error = nil;
	MADCLIDocument *cliDocument = [MADCLIDocument documentWithURL: invocation.documentURL error: &error];
	if (cliDocument == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		return MADCLIExitBadDocument;
	}

	RptqDocument *document = cliDocument.document.activeDocumentModel;
	NSSet <RptqDatabase *> *schemas = document.hasDatabaseSchemas;

	NSMutableString *out = [NSMutableString string];
	[out appendFormat: @"%@\n", invocation.documentURL.lastPathComponent];

	if (schemas.count == 0) {
		[out appendString: @"  schemas     none\n"];
	}

	NSSortDescriptor *byName = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];

	NSUInteger schemaIndex = 0;
	for (RptqDatabase *schema in schemas) {
		schemaIndex++;

		NSString *driver = schema.databaseDriverType.length > 0 ? schema.databaseDriverType : @"(unnamed)";
		NSArray <RptqDatabaseSchemaTable *> *tables =
			[[schema.hasTables allObjects] sortedArrayUsingDescriptors: @[byName]];

		[out appendFormat: @"  schema %lu   %@\n", (unsigned long)schemaIndex, driver];
		[out appendFormat: @"  tables     %lu\n", (unsigned long)tables.count];

		for (RptqDatabaseSchemaTable *table in tables) {
			NSUInteger fieldCount = table.hasFields.count;
			[out appendFormat: @"    %@ (%lu %@)\n", table.name ?: @"?",
				(unsigned long)fieldCount, fieldCount == 1 ? @"field" : @"fields"];
			for (RptqDatabaseSchemaField *field in table.hasFields) {
				[out appendFormat: @"      %@  %@%@\n", field.name ?: @"?",
					[RptqDatabaseSchemaField dataTypeDisplay: field.dataType],
					field.primaryKey ? @"  pk" : @""];
			}
		}
	}

	fputs(out.UTF8String, stdout);
	return MADCLIExitSuccess;
}
