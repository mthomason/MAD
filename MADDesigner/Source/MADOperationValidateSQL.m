//
//  MADOperationValidateSQL.m
//  MAD Designer
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationValidateSQL.h"

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADDataColumn.h>

#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADDocumentDataProtocol.h>

#import <MAD/MADocument.h>

// The operation's own domain, like the refresh's.
static NSString * const MADOperationValidateSQLErrorDomain = @"com.everydayapps.operation.validateSQL";

static const short errNoDocument = 3852;
static const short errExecute = 4;

// The enum's own names, for the mismatch warnings.
static NSString *MADValidateSQLDataTypeName(MADDataType type) {
	switch (type) {
		case MADDataTypeBit: return @"Bit";
		case MADDataTypeBlob: return @"Blob";
		case MADDataTypeDate: return @"Date";
		case MADDataTypeDateTime: return @"DateTime";
		case MADDataTypeFloat: return @"Float";
		case MADDataTypeGeometry: return @"Geometry";
		case MADDataTypeImage: return @"Image";
		case MADDataTypeInteger: return @"Integer";
		case MADDataTypeNumber: return @"Number";
		case MADDataTypeSet: return @"Set";
		case MADDataTypeString: return @"String";
		case MADDataTypeTime: return @"Time";
		case MADDataTypeTimeStamp: return @"TimeStamp";
		case MADDataTypeYear: return @"Year";
		case MADDataTypeDecimal: return @"Decimal";
		case MADDataTypeDouble: return @"Double";
		case MADDataTypeEnum: return @"Enum";
		case MADDataTypeInt24: return @"Int24";
		case MADDataTypeLong: return @"Long";
		case MADDataTypeLongLong: return @"LongLong";
		case MADDataTypeVarChar: return @"VarChar";
		default: return @"Unknown";
	}
}

@interface MADOperationValidateSQL ()

@property (nonatomic, weak) id<MADDocumentDataProtocol> document;
@property (nonatomic, copy) NSString *statement;
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *expectedColumns;

@property (nonatomic, assign) BOOL probeRan;
@property (nonatomic, assign) BOOL skipped;
@property (nonatomic, copy) NSArray<NSString *> *warnings;

@end

@implementation MADOperationValidateSQL

- (instancetype)initWithDocument:(id<MADDocumentDataProtocol>)document
					   statement:(NSString *)statement
			   expectedColumns:(NSDictionary<NSString *, NSNumber *> *)expectedColumns {
	self = [super init];
	if (!self) return nil;
	_document = document;
	_statement = [statement copy];
	_expectedColumns = [expectedColumns copy];
	return self;
}

+ (NSString *)probeSQLForStatement:(NSString *)statement database:(MADDatabase *)database {
	// The derived-table alias is mandatory in MySQL and valid in T-SQL, and
	// WHERE 1=0 folds the rows without the server having to read any.  The
	// trailing semicolon goes: the wrapper's own parens are the boundary.
	NSString *trimmed = [statement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmed.length == 0) return nil;
	if ([trimmed hasSuffix:@";"]) {
		trimmed = [trimmed substringToIndex:trimmed.length - 1];
	}
	(void)database;
	return [[NSString alloc] initWithFormat:@"SELECT * FROM (%@) AS _mad_probe WHERE 1=0", trimmed];
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) {
		return [self finish];
	}

	id<MADDocumentDataProtocol> document = self.document;
	if (document == nil) {
		NSError *error = [NSError errorWithDomain:MADOperationValidateSQLErrorDomain
											 code:errNoDocument
										 userInfo:@{ NSLocalizedDescriptionKey: @"The document is gone." }];
		[self finishWithError:error];
		return;
	}

	MADDatabase *database = document.database;

	// Credentials come from operation dependencies, exactly as the refresh
	// takes them; missing credentials skip the probe -- the structural check is
	// the whole validation then.
	MADCredential *credentials = nil;
	if ([database.databaseConnection requiresCredentials]) {
		for (NSOperation *dependency in self.dependencies) {
			if ([dependency conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)] &&
				((id<MADOperationHoldsCredentialsProtocol>)dependency).gotCredentials) {
				credentials = ((id<MADOperationHoldsCredentialsProtocol>)dependency).credentials;
			}
		}
		if (credentials == nil) {
			self.skipped = YES;
			return [self finish];
		}
	}

	NSError *connectionError = nil;
	id dbconn = [database connectWithConnection:database.databaseConnection
									 credentals:credentials
								connectionError:&connectionError];
	if (connectionError != nil || dbconn == nil) {
		// Unreachable: the probe is advisory, so this is a skip, not a failure.
		self.skipped = YES;
		return [self finish];
	}

	NSString *probeSQL = [MADOperationValidateSQL probeSQLForStatement:self.statement database:database];

	// The probe's own result table: the driver fills its columns, nothing is
	// cached, and the document's table is never touched.
	MADDataTableVirtual *resultTable = [[MADDataTableVirtual alloc] initWithNumberOfColumns:0];

	NSError *executeError = nil;
	BOOL success = [database executeSQL:probeSQL
							  fieldKeys:nil
						   onConnection:dbconn
						intoResultTable:resultTable
							  withError:&executeError];
	if (!success) {
		// The server's own message is the point of the probe.
		NSError *error = executeError;
		if (error == nil) {
			error = [NSError errorWithDomain:MADOperationValidateSQLErrorDomain
										code:errExecute
									userInfo:@{ NSLocalizedDescriptionKey: @"The probe failed",
												NSLocalizedFailureReasonErrorKey: @"The database driver reported no error." }];
		}
		[self finishWithError:error];
		return;
	}
	self.probeRan = YES;

	// The server's columns against the resolved schema fields: differences are
	// warnings, never failures.
	NSMutableArray<NSString *> *warnings = [NSMutableArray array];
	for (MADDataColumn *column in resultTable.columnsEnumerator) {
		NSString *name = column.caption.lowercaseString;
		if (name.length == 0) name = column.fieldName.lowercaseString;
		NSNumber *expectedType = self.expectedColumns[name];
		if (expectedType == nil) {
			[warnings addObject:[[NSString alloc] initWithFormat:@"The server returned a column the query did not select: '%@'.", column.caption]];
		} else if (expectedType.integerValue != (NSInteger)column.type) {
			[warnings addObject:[[NSString alloc] initWithFormat:@"Column '%@' is %@ on the server and %@ in the schema.",
								 column.caption, MADValidateSQLDataTypeName(column.type), MADValidateSQLDataTypeName((MADDataType)expectedType.integerValue)]];
		}
	}
	self.warnings = warnings;

	[self finish];
}

@end
