//
//  MTQueryCacheDeleteAllFromTable.h
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheDeleteAllFromTable_h
#define Reports_MTQueryCacheDeleteAllFromTable_h

#import "MTQuery.h"

@interface MTQueryCacheDeleteAllFromTable : MTQuery

    - (instancetype)initWithTableName:(NSString *)tableName;

@end

#endif
