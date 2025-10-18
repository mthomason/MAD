//
//  MADQueryCacheAddColumn.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryCacheAddColumn_h
#define Reports_MTQueryCacheAddColumn_h

#import "MADQueryCache.h"

@class MADDataColumn;

@interface MADQueryCacheAddColumn : MADQueryCache
	<MADQueryDatabaseProtocol>

	- (instancetype)initWithTableName:(NSString *)tableName
						   columnName:(NSString *)columnName
							   column:(MADDataColumn *)column
						  createTable:(BOOL)createTable
					 uniqueColumnHack:(BOOL)uniqueColumnHack
					   columnAffinity:(NSString *)columnAffinity;

@end

#endif
