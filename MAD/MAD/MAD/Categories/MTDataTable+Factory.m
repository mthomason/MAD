//
//  MTDataTable+Factory.m
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTable+Factory.h"
#import <Foundation/NSException.h>
#import "MTDataTableVirtual.h"
#import "MTDataTableFast.h"

@implementation MTDataTable (Factory)

+ (instancetype)dataTableFactory:(NSDictionary *)parameters NS_RETURNS_RETAINED {

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
        return [MTDataTable dataTableOfType:type withObjectId:objectId];
    } else {
        NSAssert(false, @"Not implemented.");
        return nil;
    }
}

+ (instancetype)dataTableOfType:(MTDataTableType)type withObjectId:(NSUInteger)objectId  NS_RETURNS_RETAINED {
    
    id result = nil;
    switch (type) {
        case MTDataTableTypeVirtual: {
            result = [[MTDataTableVirtual alloc] initWithId:objectId];
            break;
        }
        case MTDataTableTypePhysical: {
            result = [[MTDataTableFast alloc] initWithId:objectId];
            break;
        }
        default:
            NSAssert(false, @"Not implemented.");
            break;
    }
    return result;
    
}

+ (MTDataTable *)newDataTableForIdentifier:(NSString *)identifier NS_RETURNS_RETAINED {
    NSUInteger hash = [identifier hash];
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(hash);
    return [MTDataTable dataTableFactory:@{
                                           typeKey : type,
                                           objectIdKey : objectIdV}];
}

@end
