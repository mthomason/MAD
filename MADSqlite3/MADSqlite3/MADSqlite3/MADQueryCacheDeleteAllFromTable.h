//
//  MADQueryCacheDeleteAllFromTable.h
//  MAD
//
//  Created by Michael Thomason on 4/23/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryCacheDeleteAllFromTable_h
#define Reports_MTQueryCacheDeleteAllFromTable_h

#import <MADAPI/MADQuery.h>

@interface MADQueryCacheDeleteAllFromTable : MADQuery

	- (instancetype)initWithTableName:(NSString *)tableName;

@end

#endif
