//
//  MADQueryCacheCreateIndex.m
//  MAD
//
//  Created by Michael Thomason on 5/7/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheIndexCreate.h"

#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>

#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>

#import <MADSqlite3/MADDatabaseSqlite3.h>
#import "MADQueryCacheIndexCreateParameters.h"

@interface MADQueryCacheIndexCreate ()

@end

@implementation MADQueryCacheIndexCreate {
	NSString *_sql;
}

@synthesize dataDelegate = _dataDelegate;

- (void)dealloc {
	_dataDelegate = nil;
}

- (instancetype)initWithObject:(MADQueryCacheIndexCreateParameters *)object {
	if (self = [super initWithObject:object]) {
		
		NSArray *sortDescriptors = object.sortDescriptors;
		if (sortDescriptors.count == 0) return self;
		
		NSMutableString *sql = [[NSMutableString alloc] initWithFormat: @"CREATE INDEX IF NOT EXISTS main.%@ ON %@ (",
								object.groupName, object.tableName];

		NSDictionary *columns = object.columns;
		NSUInteger sortCounter = 0;
		for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
			
			NSString *keySortDescriptor = sortDescriptor.key;
			
			MADDataColumn *column = columns[keySortDescriptor];
			
			NSAssert(column != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
			NSString *sortDirection = [MADDatabaseSqlite3 sortDescriptionForColumnType: (MADDataType) column.nativeType
																			 ascending: sortDescriptor.ascending];
			[sql appendFormat:(sortCounter == 0) ? @"%@ %@" : @", %@ %@", keySortDescriptor, sortDirection];
			sortCounter++;
		}
		[sql appendString:@")"];
		_sql = sql;
	}
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	return _sql;
}

- (BOOL)returnsResults { return NO; }

- (MADQueryType)type {
	return MADQueryTypeCacheIndexCreateParameters;
}

@end
