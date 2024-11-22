//
//  MADTdsDb.m
//  MADTds
//
//  Created by Michael on 11/22/24.
//

#import "MADTdsDb.h"
#import <sybdb.h>

int err_handler(DBPROCESS *, int, int, int, char *, char *);
int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {

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
	self = [super init];
	if (self) {
		_hostname = hostname;
		_port = port;
		_username = username;
		_password = password;
		_database = database;
		_dbProcess = NULL;
	}
	return self;
}

- (BOOL)connect {
	LOGINREC *login;

	// Initialize DB-Library
	if (dbinit() == FAIL) {
		NSLog(@"Failed to initialize FreeTDS.");
		return NO;
	}

	dberrhandle(err_handler);

	// Set up login record
	login = dblogin();
	if (!login) {
		NSLog(@"Failed to create login record.");
		return NO;
	}

	const char *u = [self.username cStringUsingEncoding:NSUTF8StringEncoding];
	const char *p = [self.password cStringUsingEncoding:NSUTF8StringEncoding];
	const char *c = [self.database cStringUsingEncoding:NSUTF8StringEncoding];
	DBSETLAPP(login, "mad");
	DBSETLUSER(login, u);
	DBSETLPWD(login, p);
	DBSETLDBNAME(login, c);

	// Connect to the server
	NSString *serverSpec = [NSString stringWithFormat:@"%@:%d", self.hostname, self.port];
	self.dbProcess = dbopen(login, [serverSpec UTF8String]);
	if (!self.dbProcess) {
		NSLog(@"Failed to connect to the database server.");
		return NO;
	}

	// Select the database
	if (dbuse(self.dbProcess, [self.database UTF8String]) == FAIL) {
		NSLog(@"Failed to select the database: %@", self.database);
		[self disconnect];
		return NO;
	}

	NSLog(@"Connected successfully to %@.", self.hostname);
	return YES;
}

- (NSArray<NSDictionary *> *)executeQuery:(NSString *)query {
	NSMutableArray<NSDictionary *> *results = [NSMutableArray array];

	if (dbcmd(self.dbProcess, [query UTF8String]) == FAIL) {
		NSLog(@"Failed to set query: %@", query);
		return results;
	}

	if (dbsqlexec(self.dbProcess) == FAIL) {
		NSLog(@"Failed to execute query: %@", query);
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
				if (value) {
					row[[NSString stringWithUTF8String:columnName]] = [NSString stringWithUTF8String:value];
				} else {
					row[[NSString stringWithUTF8String:columnName]] = [NSNull null];
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
	NSLog(@"Disconnected from the database.");
}

@end

