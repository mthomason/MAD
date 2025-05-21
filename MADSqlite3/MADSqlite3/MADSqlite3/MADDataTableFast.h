//
//  MADDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDataTableFast_h
#define Reports_MADDataTableFast_h

#import <MADFoundation/MADDataTable.h>

@protocol MADCacheProtocol, MADDataProtocol, MADQueryDataBindingProtocol;

@class MADQuery, MADDatabaseSqlite3;

NS_ASSUME_NONNULL_BEGIN

@interface MADDataTableFast : MADDataTable <NSCoding, NSFastEnumeration>

	@property (nonatomic, strong, readonly) MADDatabaseSqlite3 *databaseForSelects;

	@property (nonatomic, weak) IBOutlet id <MADCacheProtocol> cacheDelegate;
	@property (nonatomic, weak) IBOutlet id <MADDataProtocol> dataDelegate;

	- (NSString *)tableName;
	- (nullable NSString *)columnKeyForColumnName:(NSString *)columnName;
	- (NSArray *)whereClauseForGroupKeys:(NSArray *)groupKeys;

	- (__kindof NSObject <NSCopying, NSSecureCoding> *)runSelectQuery:(MADQuery <MADQueryDataBindingProtocol> *)query;

	- (NSDictionary *)dataForRow:(NSUInteger)cacheId
						  column:(NSString *)columnIdentifier
						   error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
