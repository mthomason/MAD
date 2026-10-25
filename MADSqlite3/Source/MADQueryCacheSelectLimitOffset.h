//
//  MADQueryCacheSelectLimitOffset.h
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryCacheSelectLimitOffset_h
#define Reports_MTQueryCacheSelectLimitOffset_h

#import <MADAPI/MADQuery.h>

@class MADDataColumn, NSSortDescriptor;

@interface MADQueryCacheSelectLimitOffset : MADQuery

	- (instancetype)initWithColumnKeys: (NSArray <NSString *> *)columnKeys
							 tableName: (NSString *)tableName
					   sortDescriptors: (NSArray <NSSortDescriptor *> *)sortDescriptors
								 limit: (NSUInteger)limit
								offset: (NSUInteger)offset
							 dropRowID: (BOOL)dropRowID
							   columns: (NSDictionary <NSString *, MADDataColumn *> *)columns;

@end

#endif
