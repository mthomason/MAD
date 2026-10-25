//
//  MADDataTable+Constructor.m
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDataTable+Constructor.h"

#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTableVirtual.h>

#import <MADSqlite3/MADDataTableFast.h>

@implementation MADDataTable (Constructor)

+ (instancetype)newDataTableWithDefinition:(NSDictionary *)parameters {

	NSNumber *keyDataTableType = [[NSNumber alloc] initWithShort: MADDataTableParametersType];
	NSNumber *keyDataTableObjectId = [[NSNumber alloc] initWithShort: MADDataTableParametersIdentifier];
	
	NSNumber *dataTableType = parameters[keyDataTableType];
	NSNumber *dataTableObjectId = parameters[keyDataTableObjectId];
	
	BOOL objectIdSet = NO;
	
	//Default type is virtual. If there is no object id, then type MUST be virtual.  That's
	//  because we won't know where to store it.
	MADDataTableType type = MADDataTableTypeVirtual;
	NSUInteger objectId = 0;
	if (dataTableType != nil && dataTableObjectId != nil) {
		type = dataTableType.shortValue;
	}
	
	if (dataTableObjectId != nil) {
		objectIdSet = YES;
		objectId = dataTableObjectId.unsignedIntegerValue;
	}
	if (objectIdSet) {
		return [self newDataTableOfType:type withObjectID:objectId];
	} else {
		NSAssert(NO, @"Not implemented.");
		return nil;
	}
}

+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	return [self newDataTableOfType:type withObjectID:objectID cacheDirectory:nil];
}

+ (instancetype)newDataTableOfType:(MADDataTableType)type
					  withObjectID:(NSUInteger)objectID
					cacheDirectory:(NSURL *)cacheDirectory {

	__kindof MADDataTable *result = nil;
	switch (type) {
		case MADDataTableTypeVirtual: {
			// A virtual table keeps its rows in memory and never caches, so the
			// directory has nothing to say for it.
			result = [[MADDataTableVirtual alloc] initWithId:objectID];
			break;
		}
		case MADDataTableTypePhysical: {
			result = [[MADDataTableFast alloc] initWithId:objectID cacheDirectory:cacheDirectory];
			break;
		}
		default:
			NSAssert(NO, @"Not implemented.");
			break;
	}
	return result;
	
}

+ (instancetype)newDataTableForIdentifier:(NSString *)identifier {
	
	NSDictionary *definition;
	NSNumber *typeKey = [[NSNumber alloc] initWithShort: MADDataTableParametersType];
	NSNumber *type = [[NSNumber alloc] initWithShort: MADDataTableTypeVirtual];
	NSNumber *objectIdKey = [[NSNumber alloc] initWithShort: MADDataTableParametersIdentifier];
	NSNumber *objectIdV =  [[NSNumber alloc] initWithUnsignedInteger: identifier.hash];
	
	definition = [[NSDictionary alloc] initWithObjectsAndKeys:
				  type, typeKey,
				  objectIdV, objectIdKey, nil];
	
	return [self newDataTableWithDefinition:definition];
}

@end
