//
//  MTSqlite3.m
//  Reports
//
//  Created by Michael Thomason on 1/24/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTSqlite3.h"

@interface MTSqlite3 ()

@property (nonatomic, retain) NSURL *datastore;
@property (assign) sqlite3 *database;

@end

@implementation MTSqlite3

- (void)dealloc {
    [_datastore release];
    [super dealloc];
}

- (id)initWithSqlite3Database:(NSURL *)path {
    self = [super init];
    if (self) {
        [self setDatastore:path];
    }
    return self;
}


- (void)openDatabases {
	if (sqlite3_open([[[self datastore] absoluteString] UTF8String], &self->_database) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to open database with message '%s'.", sqlite3_errmsg(self->_database));
	} else {
		sqlite3_extended_result_codes(self->_database, true);
	}
}

- (void)closeDatabases {
	if (sqlite3_close(self->_database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(self->_database));
    }
}

@end