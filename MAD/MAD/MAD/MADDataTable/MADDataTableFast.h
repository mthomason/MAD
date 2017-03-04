//
//  MADDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDataTableFast_h
#define Reports_MADDataTableFast_h

#import "MADDataTable.h"

@protocol MADCacheProtocol, MADDataProtocol;

@class MTQuery, MTDatabaseSqlite3;

@interface MADDataTableFast : MADDataTable
    <NSCoding, NSFastEnumeration>

    @property (nonatomic, strong, readonly) MTDatabaseSqlite3 *databaseForSelects;

    @property (nonatomic, weak) IBOutlet id <MADCacheProtocol> cacheDelegate;
    @property (nonatomic, weak) IBOutlet id <MADDataProtocol> dataDelegate;

    - (NSString *)tableName;
    - (NSString *)columnKeyForColumnName:(NSString *)columnName;
    - (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys;

    - (id)runSelectQuery:(MTQuery *)query;

    - (NSDictionary *)copyDataForCacheId:(NSUInteger)cacheId andColumnIdentifier:(NSString *)columnIdentifier;

@end

#endif
