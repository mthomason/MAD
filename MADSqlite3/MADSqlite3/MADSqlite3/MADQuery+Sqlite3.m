//
//  MADQuery+Sqlite3.m
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQuery+Sqlite3.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>   //FIXME: Should only be included in Cache subset
#import "madlog.h"
@implementation MADQuery (Sqlite3)

- (NSString *)orderByClauseWithSortDescriptors:(NSArray <NSSortDescriptor *> *)sortDescriptors {
	NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
	if (sortDescriptors.count > 0) {
		[sql appendString:@" ORDER BY "];

		NSUInteger sortCounter = 0;
		
		for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
			if (sortCounter != 0) [sql appendString:@", "];

			MADDataColumn *dataColumn = nil;
			if ([self conformsToProtocol:@protocol(MADQueryColumnsProtocol)]) {
				if (((MADQuery <MADQueryColumnsProtocol> *)self).columns != nil) {
					NSString *key = sortDescriptor.key;
					if (key != nil) {
						dataColumn = ((MADQuery <MADQueryColumnsProtocol> *)self).columns[key];
					}
				}
			}
			NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
			NSString *sortDirection = [MADDatabaseSqlite3 sortDescriptionForColumnType: dataColumn.nativeType
																			 ascending: sortDescriptor.ascending];
			[sql appendFormat:@"%@ %@", sortDescriptor.key, sortDirection];
			sortCounter++;
		}
	}
	return sql;
}

- (NSString *)whereClauseWithParameters:(NSArray <NSDictionary *> *)whereClause {
	NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
	if (whereClause.count > 0) {
		NSUInteger counter = 0, counterBinings = 0;
		for (NSDictionary *condition in whereClause) {
			[sql appendString: (counter == 0) ? @" WHERE " : @" AND "];
			NSString *columnHandle = condition[@"c"];
			NSString *columnValue = condition[@"v"];
			
			
			MADDatabaseDataBinding *databinding;
			if ([[NSNull null] isEqual: columnValue]) {
				databinding = [[MADDatabaseDataBinding alloc] initWithDataType: MADDataTypeNull
																	fieldIndex: counterBinings
																		 value: columnValue];
			} else {
				databinding = [[MADDatabaseDataBinding alloc] initWithDataType: [self columnTypeForColumnHandle:columnHandle]
																	fieldIndex: counterBinings
																		 value: columnValue];
			}
			if ([self conformsToProtocol:@protocol(MADQueryDataBindingProtocol)]) {
				[((MADQuery <MADQueryDataBindingProtocol> *)self).binaryBindings addObject:databinding];
			}
			[sql appendFormat:@"%@ = ?", columnHandle];
			counterBinings++;
			counter++;
		}
	}
	return sql;
}

- (NSString *)whereClauseWithRowIds:(NSArray <NSNumber *> *)rowids {
	NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
	BOOL firstTime = YES;
	if (rowids.count > 0) {
		for (NSNumber *rowido in rowids) {
			[sql appendString: firstTime == NO ? @" OR " : @" WHERE "];
			[sql appendFormat:@"rowid = %lu", (unsigned long)rowido.unsignedIntegerValue];
			firstTime = NO;
		}
	} else {
		[sql setString:@" WHERE rowid = -1 "];
	}
	return sql;
}

- (MADDataType)columnTypeForColumnHandle:(NSString *)columnHandle {
	MADDataColumn *column;
	if ([self conformsToProtocol:@protocol(MADQueryColumnsProtocol)]) {
		column = ((id <MADQueryColumnsProtocol>)self).columns[columnHandle];
	} else {
		os_log_error(GetMadLog(), "No column handle for: %@", columnHandle);
	}
	return column != nil ? column.type : 0;
}

@end
