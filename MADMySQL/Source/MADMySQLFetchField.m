//
//  MADMySQLFetchField.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLFetchField.h"

#import <Foundation/NSString.h>

#import <mysql.h>

@implementation MADMySQLFetchField

- (instancetype)initWithField:(MYSQL_FIELD)field fieldName:(NSString *)fieldName {
	if ((self = [super init])) {
		_name = [fieldName copy];
		_fieldType = (NSInteger)field.type;
		_width = (NSUInteger)field.length;
		_decimals = (NSUInteger)field.decimals;
		_primaryKey = IS_PRI_KEY(field.flags) ? YES : NO;
	}
	return self;
}

@end
