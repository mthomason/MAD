//
//  MTDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTableFast_h
#define Reports_MTDataTableFast_h

#import "MTDataTable.h"

@protocol MTCacheProtocol;
@protocol MADDataProtocol;

@class MTDatabaseCache;
@class MTQuery;
@class MTDatabaseSqlite3;

@interface MTDataTableFast : MTDataTable
    <NSCoding, NSFastEnumeration>

    @property (nonatomic, strong, readonly) MTDatabaseSqlite3 *databaseForSelects;

    @property (nonatomic, weak) IBOutlet id <MTCacheProtocol> cacheDelegate;
    @property (nonatomic, weak) IBOutlet id <MADDataProtocol> dataDelegate;

    - (NSString *)tableName;
    - (NSString *)columnKeyForColumnName:(NSString *)columnName;
    - (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys;

    - (id)runSelectQuery:(MTQuery *)query;

@end

#endif
