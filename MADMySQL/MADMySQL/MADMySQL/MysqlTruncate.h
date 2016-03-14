//
//  MysqlTruncate.h
//  mysql_connector
//
//  Created by Bill Allen on 8/22/11.
//  Copyright 2011 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlTruncate_h
#define MAD_MysqlTruncate_h

#import <Foundation/NSObject.h>

@class MysqlConnection;

@interface MysqlTruncate : NSObject {
    NSString *tableName;
    MysqlConnection *connection;
}

@property(copy) NSString *tableName;

+ (MysqlTruncate *)truncateWithConnection:(MysqlConnection *)aConnection;
+ (MysqlTruncate *)truncateWithConnection:(MysqlConnection *)aConnection forTable:(NSString *)aTableName;
- (void)execute;

@end

#endif
