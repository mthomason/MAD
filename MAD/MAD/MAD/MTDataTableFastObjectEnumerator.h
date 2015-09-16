//
//  MTDataTableFastObjectEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTableFastObjectEnumerator_h
#define Reports_MTDataTableFastObjectEnumerator_h

#import <Foundation/Foundation.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import <MADSqlite3/MADSqlite3.h>

@class MTDatabaseConnection, MTQuery;

@interface MTDataTableFastObjectEnumerator : NSEnumerator

@property (nonatomic, assign) BOOL addRowId;
@property (nonatomic, assign) BOOL singleColumnNoWrapper;    //No wrapper on this.

- (instancetype)initWithDatabaseConnection: (MTDatabaseConnection *)databaseConnection
                                   columns: (NSDictionary *)columns
                                columnKeys: (NSArray *)columnKeys
                                     query: (MTQuery *)query;

@end

#endif
