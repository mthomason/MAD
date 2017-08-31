//
//  MysqlFetch.h
//  mysql_connector
//
//  Created by Karl Kraft on 4/25/07.
//  Copyright 2007-2010 Karl Kraft. All rights reserved.
//

#ifndef MADMySQL_MysqlFetch_h
#define MADMySQL_MysqlFetch_h

#import <Foundation/NSObject.h>
#import "mysql.h"

@class MysqlConnection, MADQuery, MADDataTable;

@protocol MADMySQLFetchProtocol
  @optional
    - (MADDataTable *)dataTableForQuery:(MADQuery *)query;
    - (void)didFetchRow:(NSUInteger)row;
@end

@interface MysqlFetch : NSObject

    @property(nonatomic, weak) id <MADMySQLFetchProtocol> delegate;

    @property(nonatomic, strong, readwrite) NSArray *fieldNames;
    @property(nonatomic, strong, readwrite) NSArray *fields;

    + (int)fetchStatement:(MYSQL_STMT *)statement;

    char *mySQLTypeForType(int type);

@end

#endif
