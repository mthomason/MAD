//
//  MTQueryCacheAddColumn.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheAddColumn_h
#define Reports_MTQueryCacheAddColumn_h

#import "MTQueryCache.h"

@class MADDataColumn;

@interface MADQueryCacheAddColumn : MTQueryCache
    <MADQueryDatabaseProtocol>

    - (instancetype)initWithTableName:(NSString *)tableName
                           columnName:(NSString *)columnName
                               column:(MADDataColumn *)column
                          createTable:(BOOL)createTable
                     uniqueColumnHack:(BOOL)uniqueColumnHack
                       columnAffinity:(NSString *)columnAffinity;

@end

#endif
