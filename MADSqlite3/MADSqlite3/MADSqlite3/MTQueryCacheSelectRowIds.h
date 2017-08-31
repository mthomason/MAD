//
//  MTQueryCacheRowIds.h
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQueryCacheSelectRowIds_h
#define Reports_MTQueryCacheSelectRowIds_h

#import <MADAPI/MADQuery.h>

@interface MTQueryCacheSelectRowIds : MADQuery
    <MADQueryColumnsProtocol>

- (instancetype)initWithRowIDs:(NSArray *)rowIDs tableName:(NSString *)tableName
               sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns;

@end

#endif
