//
//  MysqlInsert.h
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlInsert_h
#define MAD_MysqlInsert_h

#import <Foundation/NSObject.h>

@class MysqlConnection;

@interface MysqlInsert : NSObject {
	MysqlConnection *connection;
}

	@property(nonatomic, readwrite, assign) BOOL ignoreDuplicateErrors;

	@property(nonatomic, readwrite, copy) NSString *table;
	@property(nonatomic, readwrite, copy) NSDictionary  *rowData;
	@property(nonatomic, readonly, strong) NSNumber *affectedRows;
	@property(nonatomic, readonly, strong) NSNumber *rowid;

	+ (MysqlInsert *)insertWithConnection:(MysqlConnection *)aConnection;
	- (void)execute;

@end

#endif
