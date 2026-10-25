//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADTdsDb.m
//  MADTds
//
//  Created by Michael Thomason on 11/22/24.
//

#import "MADTdsDb.h"
#import "sybdb.h"

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSNotification.h>

#import <MADFoundation/madlog.h>

int err_handler(DBPROCESS *, int, int, int, char *, char *);
int err_handler(DBPROCESS *__unused dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {

	int result = INT_CANCEL;

	
		if (severity >= 5 || dberr == SYBEINTF) {
			NSString *title = NSLocalizedString(@"Caught an Error", @"Caught an Error");
			char *osstr = (oserrstr != NULL ? oserrstr : "");
			char *dbstr = (dberrstr != NULL ? dberrstr : "");
			
			NSString *systemMessage = @(osstr);
			NSString *dbMessage = @(dbstr);
			NSString *errorMessage = [[NSString alloc] initWithFormat:@"System says: \"(%d)%@.\"\nDatabase says: \"(%d)%@.\"", oserr, systemMessage, dberr, dbMessage];
			
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : errorMessage};
			NSError *error = [NSError errorWithDomain:@"MADTds" code:dberr userInfo:errorInfo];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MADNotificationError" object:error];
			
			result = INT_CANCEL;
		}
	
	return result;
}

@interface MADTdsDb ()

@property (nonatomic, assign) DBPROCESS *dbProcess;

@end

@implementation MADTdsDb

- (instancetype)initWithHost:(NSString *)hostname
						port:(int)port
					username:(NSString *)username
					password:(NSString *)password
					database:(NSString *)database {
	if (self = [super init]) {
		_hostname = [hostname copy];
		_port = port;
		_username = [username copy];
		_password = [password copy];
		_database = [database copy];
		_dbProcess = NULL;
	}
	return self;
}

- (BOOL)connect {
	LOGINREC *login;

	if (dbinit() == FAIL) {
		os_log(GetTdsLog(), "Failed to initialize TDS.");
		return NO;
	}

	dberrhandle(err_handler);

	// Set up login record
	login = dblogin();
	if (!login) {
		os_log(GetTdsLog(), "Failed to create login record.");
		return NO;
	}

	const char *u = [self.username cStringUsingEncoding:NSUTF8StringEncoding];
	const char *p = [self.password cStringUsingEncoding:NSUTF8StringEncoding];
	const char *c = [self.database cStringUsingEncoding:NSUTF8StringEncoding];
	DBSETLAPP(login, "mad");
	DBSETLUSER(login, u);
	DBSETLPWD(login, p);
	DBSETLDBNAME(login, c);

	NSString *serverSpec = [NSString stringWithFormat:@"%@:%d", self.hostname, self.port];
	self.dbProcess = dbopen(login, [serverSpec UTF8String]);
	if (!self.dbProcess) {
		os_log(GetTdsLog(), "Failed to connect to the database server.");
		return NO;
	}

	// Select the database
	if (dbuse(self.dbProcess, [self.database UTF8String]) == FAIL) {
		os_log(GetTdsLog(), "Failed to select the database: %@", self.database);
		[self disconnect];
		return NO;
	}

	os_log(GetTdsLog(), "Connected successfully to %@.", self.hostname);
	return YES;
}

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)query {
	NSMutableArray<NSDictionary *> *results = [NSMutableArray array];

	if (dbcmd(self.dbProcess, [query UTF8String]) == FAIL) {
		os_log(GetTdsLog(), "Failed to set query: %s", query.UTF8String);
		return results;
	}

	if (dbsqlexec(self.dbProcess) == FAIL) {
		os_log(GetTdsLog(), "Failed to execute query: %s", query.UTF8String);
		return results;
	}

	while (dbresults(self.dbProcess) != NO_MORE_RESULTS) {
		if (DBROWS(self.dbProcess) != SUCCEED) {
			continue;
		}

		int numColumns = dbnumcols(self.dbProcess);
		while (dbnextrow(self.dbProcess) != NO_MORE_ROWS) {
			NSMutableDictionary *row = [NSMutableDictionary dictionary];
			for (int col = 1; col <= numColumns; col++) {
				char *columnName = dbcolname(self.dbProcess, col);
				char *value = (char *)dbdata(self.dbProcess, col);
				// A NULL or non-UTF-8 column name would make the dictionary key nil,
				// which throws; skip the column instead.
				if (columnName == NULL) continue;
				NSString *columnKey = [NSString stringWithUTF8String:columnName];
				if (columnKey == nil) continue;
				if (value) {
					row[columnKey] = [NSString stringWithUTF8String:value];
				} else {
					row[columnKey] = [NSNull null];
				}
			}
			[results addObject:row];
		}
	}

	return results;
}

- (void)disconnect {
	if (self.dbProcess) {
		dbclose(self.dbProcess);
		self.dbProcess = NULL;
	}
	dbexit();
	os_log(GetTdsLog(), "Disconnected from the database.");
}

@end

