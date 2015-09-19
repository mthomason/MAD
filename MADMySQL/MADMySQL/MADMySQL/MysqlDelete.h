//
//  MysqlDelete.h
//  mysql_connector
//
//  Created by Karl Kraft on 9/28/08.
//  Copyright 2008-2011 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlDelete_h
#define MAD_MysqlDelete_h

#import <Foundation/Foundation.h>

@class MysqlConnection;

@interface MysqlDelete : NSObject {
    MysqlConnection *connection;
    NSString *tableName;
    NSString *qualifier;
    NSNumber *affectedRows;
}

@property(copy) NSString *tableName;
@property(copy) NSString *qualifier;
@property(readonly) NSNumber *affectedRows;

+ (MysqlDelete *)deleteWithConnection:(MysqlConnection *)aConnection;
- (void)execute;

@end

#endif
