//
//  MADQueryCacheRowIds.h
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryCacheSelectRowIds_h
#define Reports_MTQueryCacheSelectRowIds_h

#import <MADAPI/MADQuery.h>

@interface MADQueryCacheSelectRowIds : MADQuery
	<MADQueryColumnsProtocol>

- (instancetype)initWithRowIDs:(NSArray *)rowIDs tableName:(NSString *)tableName
			   sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns;

@end

#endif
