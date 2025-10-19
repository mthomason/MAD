//
//  MysqlUpdate.h
//  mysql_connector
//
//  Created by Karl Kraft on 6/12/08.
//  Copyright 2008-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlUpdate_h
#define MAD_MysqlUpdate_h

#import <Foundation/NSObject.h>

@class MysqlConnection;

@interface MysqlUpdate : NSObject {
	MysqlConnection *connection;
}

	@property(nonatomic, strong) NSString *table;
	@property(nonatomic, strong) NSDictionary *rowData;
	@property(nonatomic, strong) NSDictionary *qualifier;
	@property(nonatomic, readonly) NSNumber *affectedRows;

	+ (MysqlUpdate *)updateWithConnection:(MysqlConnection *)aConnection;
	- (void)execute;

@end

#endif
