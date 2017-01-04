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
#import "MTDataTableVirtual.h"
#import "MTDataTableFast.h"

@implementation MTDataTable

+ (instancetype)newDataTableWithDefinition:(NSDictionary *)parameters {

    NSNumber *keyDataTableType = [[NSNumber alloc] initWithShort: MTDataTableTypeOfTable];
    NSNumber *keyDataTableObjectId = [[NSNumber alloc] initWithShort: MTDataTableObjectId];
    
    NSNumber *dataTableType = parameters[keyDataTableType];
    NSNumber *dataTableObjectId = parameters[keyDataTableObjectId];
    
    BOOL objectIdSet = NO;
    
    //Default type is virtual. If there is no object id, then type MUST be virtual.  That's
    //  because we won't know where to store it.
    MTDataTableType type = MTDataTableTypeVirtual;
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

+ (instancetype)newDataTableOfType:(MTDataTableType)type withObjectID:(NSUInteger)objectID {
    
    id result = nil;
    switch (type) {
        case MTDataTableTypeVirtual: {
            result = [[MTDataTableVirtual alloc] initWithId:objectID];
            break;
        }
        case MTDataTableTypePhysical: {
            result = [[MTDataTableFast alloc] initWithId:objectID];
            break;
        }
        default:
            NSAssert(NO, @"Not implemented.");
            break;
    }
    return result;
    
}

+ (MTDataTable *)newDataTableForIdentifier:(NSString *)identifier {
    NSUInteger hash = identifier.hash;
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    NSDictionary *definition = @{typeKey : type,
                                 objectIdKey : objectIdV};
    return [MTDataTable newDataTableWithDefinition:definition];
}

@end
