//
//  MTDataTable+Factory.m
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTable.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import "MADDataTableVirtual.h"
#import "MADDataTableFast.h"

@implementation MTDataTable

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
    
    id result = nil;
    switch (type) {
        case MADDataTableTypeVirtual: {
            result = [[MADDataTableVirtual alloc] initWithId:objectID];
            break;
        }
        case MADDataTableTypePhysical: {
            result = [[MADDataTableFast alloc] initWithId:objectID];
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
