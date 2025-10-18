//
//  MNSDatabaseTable.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseTable.h"
#import <Foundation/NSString.h>

@implementation MADDatabaseTable

- (instancetype)init {
	self = [self initWithTableName:nil];
	return self;
}

- (instancetype)initWithTableName:(NSString *)tableName {
	if (self = [super init]) {
		_name = [tableName copyWithZone:nil];
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
	MADDatabaseTable *copy = [[[self class] allocWithZone:zone] initWithTableName:_name];
	copy.queryable = _queryable;
	return copy;
}

@end
