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
    NSString *table;
    NSDictionary *rowData;
    NSDictionary *qualifier;
    NSNumber *affectedRows;
}

@property(retain) NSString *table;
@property(retain) NSDictionary  *rowData;
@property(retain) NSDictionary  *qualifier;
@property(readonly) NSNumber *affectedRows;

+ (MysqlUpdate *)updateWithConnection:(MysqlConnection *)aConnection;
- (void)execute;

@end

#endif
