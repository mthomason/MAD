//
//  MysqlFetch.h
//  mysql_connector
//
//  Created by Karl Kraft on 4/25/07.
//  Copyright 2007-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlFetch_h
#define MAD_MysqlFetch_h

#import <Foundation/Foundation.h>
#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MTDataColumn.h>
#import "mysql.h"

@class MysqlConnection, MTDataTable, MTQuery;

@protocol MysqlFetchDelegate
@optional
    - (MTDataTable * _Null_unspecified)dataTableForQuery:(MTQuery * _Null_unspecified)query;
    - (void)didFetchRow:(NSUInteger)row;
@end

@interface MysqlFetch : NSObject

@property (nonatomic, weak) id <MysqlFetchDelegate> delegate;

- (MTDataTable * _Null_unspecified)fetchWithCommand:(NSString * _Null_unspecified)s
                                          dataTable:(MTDataTable * _Null_unspecified * _Null_unspecified)dataTable
                                       onConnection:(MysqlConnection * _Null_unspecified)connection
                                              error:(NSError * _Nullable * _Null_unspecified)error;

@end

#endif
