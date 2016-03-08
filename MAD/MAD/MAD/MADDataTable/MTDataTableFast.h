//
//  MTDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTableFast_h
#define Reports_MTDataTableFast_h

#import <MADFoundation/MTDataTable.h>

@class MTDatabaseCache, MTQuery;

@interface MTDataTableFast : MTDataTable
    <NSCoding, NSFastEnumeration>

@property (nonatomic, strong, readonly) MTDatabaseCache *databaseForSelects;

- (NSString *)tableName;
- (NSString *)columnKeyForColumnName:(NSString *)columnName;
- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys;

- (id)runSelectQuery:(MTQuery *)query;

@end

#endif
