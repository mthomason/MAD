//
//  MADQueryCacheIndexCreateTemplate.m
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryCacheIndexCreateTemplate.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

#import "MADCacheIndexType.h"
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheIndexCreateTemplate ()
@end

@implementation MADQueryCacheIndexCreateTemplate {
	NSUInteger _groupCount;
}

- (instancetype)initWithObject:(id)object {
	if (self = [super initWithObject:object]) {
		
		NSAssert([object isKindOfClass:[NSDictionary class]], @"MADQueryCacheIndexDrop expects NSDictionary.");

		NSDictionary *obj = object;
		NSNumber *keyGroupCount = [[NSNumber alloc] initWithShort:MADCacheIndexTypeGroupCount];
		NSNumber *groupCount = [[obj objectForKey: keyGroupCount] copy];
		_groupCount = groupCount.unsignedIntegerValue;

	}
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	NSMutableString *sql;
	if (_groupCount > 0) {
		sql = [[NSMutableString alloc] initWithString:@"CREATE INDEX IF NOT EXISTS main.? ON ? ("];
		for (NSUInteger i = 0; i < _groupCount; i++) {
			
			if (i != 0) [sql appendString:@", ? ?"];
			else [sql appendString:@"? ?"];
		}
		[sql appendString:@" )"];
	}
	
	return sql;
}

- (BOOL)returnsResults { return NO; }

- (NSUInteger)parameterCount {
	return _groupCount * 2 + 2;
}

- (MADQueryType)type {
	return MADQueryTypeCacheIndexCreateTemplate;
}

@end
