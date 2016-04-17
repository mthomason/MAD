//
//  MTDataTable+Factory.m
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTable+Factory.h"
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import "MTDataTableVirtual.h"
#import <MAD/MTDataTableFast.h>

@implementation MTDataTable (Factory)

+ (instancetype)newDataTableWithDefinition:(NSDictionary *)parameters {

    NSNumber *keyDataTableType = @(MTDataTableTypeOfTable);
    NSNumber *keyDataTableObjectId = @(MTDataTableObjectId);
    
    NSNumber *dataTableType = parameters[keyDataTableType];
    NSNumber *dataTableObjectId = parameters[keyDataTableObjectId];
    
    BOOL objectIdSet = NO;
    
    //Default type is virtual. If there is no object id, then type MUST be virtual.  That's
    //  because we won't know where to store it.
    MTDataTableType type = MTDataTableTypeVirtual;
    NSUInteger objectId = 0;
    if (dataTableType != nil && dataTableObjectId != nil) {
        type = [dataTableType unsignedIntegerValue];
    }
    
    if (dataTableObjectId != nil) {
        objectIdSet = YES;
        objectId = [dataTableObjectId unsignedIntegerValue];
    }
    if (objectIdSet) {
        return [MTDataTable newDataTableOfType:type withObjectID:objectId];
    } else {
        NSAssert(false, @"Not implemented.");
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
            NSAssert(false, @"Not implemented.");
            break;
    }
    return result;
    
}

+ (instancetype)newDataTableForIdentifier:(NSString *)identifier {
    return [self newDataTableOfType:MTDataTableTypeVirtual withObjectID:identifier.hash];
}

@end
