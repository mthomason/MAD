//
//  MysqlFetch.h
//  mysql_connector
//
//  Created by Karl Kraft on 4/25/07.
//  Copyright 2007-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlFetch_h
#define MAD_MysqlFetch_h

#import <Foundation/NSObject.h>
#import "mysql.h"

@class MysqlConnection, MTQuery, MTDataTable;

@protocol MysqlFetchDelegate
@optional
    - (MTDataTable *)dataTableForQuery:(MTQuery *)query;
    - (void)didFetchRow:(NSUInteger)row;
@end

@interface MysqlFetch : NSObject

    @property(nonatomic, weak) id <MysqlFetchDelegate> delegate;

    @property(strong, readwrite) NSArray *fieldNames;
    @property(strong, readwrite) NSArray *fields;

    + (int)fetchStatement:(MYSQL_STMT *)statement;

    char *mySQLTypeForType(int type);

@end

#endif
