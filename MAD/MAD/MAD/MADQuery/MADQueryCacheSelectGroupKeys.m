//
//  MADQueryCacheSelectGroupKeys.m
//  MAD
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryCacheSelectGroupKeys.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADQuerySelectParameters.h>

#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheSelectGroupKeys ()

@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, copy) NSString *columnName;
@property (nonatomic, copy) NSString *sqlSpeedSorting;
@property (nonatomic, copy) NSString *sqlSpeedPredicate;

@property (nonatomic, assign) BOOL accending;

@end

@implementation MADQueryCacheSelectGroupKeys

- (instancetype)initWithObject:(id)object {
	
	if (self = [super initWithObject:object]) {
		
		NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
		NSDictionary *obj = object;
		
		NSNumber *keySelectTableName = @(MADQuerySelectTableName);
		NSString *selectTableName = [obj objectForKey:keySelectTableName];
		NSString *tableName = [[NSString alloc] initWithString:selectTableName];
		self.tableName = tableName;
		
		NSNumber *keySelectPredicates = @(MADQuerySelectPredicates);
		NSMutableString *sqlPredicate = [[NSMutableString alloc] initWithString:@" WHERE "];
		NSArray *selectPredicates = [obj objectForKey:keySelectPredicates];
		int i = 0;
		for (NSDictionary *predicate in selectPredicates) {
			
			NSString *left = predicate[MADQueryKeyPredicateColumn];
			NSString *right = predicate[MADQueryKeyPredicateValue];
			if (i > 0) {
				[sqlPredicate appendString:@" AND "];
			}
			[sqlPredicate appendFormat:@"%@ = \"%@\"", left, right];
			i++;
		}
		self.sqlSpeedPredicate = sqlPredicate;
		
		NSNumber *keySelectFieldNames = @(MADQuerySelectFieldKeys);
		NSArray <NSString *> *fieldNames = [obj objectForKey:keySelectFieldNames];
		NSString *columnName = [fieldNames.firstObject copy];
		self.columnName = columnName;
		
		NSNumber *keySelectSortAccending = @(MADQuerySelectSortAccending);
		NSNumber *sortValue = [[obj objectForKey: keySelectSortAccending] copy];
		self.accending = sortValue.boolValue;
		
		NSNumber *keyColumns = @(MADQuerySelectColumns);
		NSDictionary *columns = [obj objectForKey: keyColumns];
		MADDataColumn *dataColumn = [columns objectForKey: columnName];
		
		NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
		self.sqlSpeedSorting = [MADDatabaseSqlite3 sortDescriptionForColumnType:dataColumn.nativeType
																	  ascending:self.accending];
		
	}
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	NSString *result = [[NSString alloc] initWithFormat:@"SELECT DISTINCT %@ FROM %@ %@ ORDER BY %@ %@",
						self.columnName, self.tableName,
						self.sqlSpeedPredicate, self.columnName, self.sqlSpeedSorting];
	return result;
}

- (MADQueryType)type {
	return MADQueryTypeCacheSelectGroupKeys;
}

@end
