//
//  MTQueryCacheAddColumn.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheAddColumn_h
#define Reports_MTQueryCacheAddColumn_h

#import "MTQueryCache.h"

@class MADDataColumn;

@interface MTQueryCacheAddColumn : MTQueryCache

    - (instancetype)initWithTableName:(NSString *)tableName columnName:(NSString *)columnName
                               column:(MADDataColumn *)column createTable:(bool)createTable
                     uniqueColumnHack:(bool)uniqueColumnHack
                       columnAffinity:(NSString *)columnAffinity;

@end

#endif
