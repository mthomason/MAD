//
//  MADQueryCacheRowIds.h
//  MAD
//
//  Created by Michael Thomason on 5/24/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
