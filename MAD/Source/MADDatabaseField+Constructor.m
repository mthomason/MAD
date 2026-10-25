//
//  MADDatabaseField+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDatabaseField+Constructor.h"
#import <Foundation/NSString.h>
#import "RptqDatabaseSchemaField.h"

@implementation MADDatabaseField (Constructor)

+ (instancetype)newDatabaseFieldWithSchemaField:(RptqDatabaseSchemaField *)schemaField {
	MADDatabaseField *result = [[MADDatabaseField alloc] init];
	result.name = schemaField.name.copy;
	result.fieldType = schemaField.dataType;
	result.fieldTypeNative = schemaField.dataTypeNative;
	result.decimals = schemaField.decimals;
	result.primaryKey = schemaField.primaryKey;
	return result;
}

@end
