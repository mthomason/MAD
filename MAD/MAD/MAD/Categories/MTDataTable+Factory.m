//
//  MTDataTable+Factory.m
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTable+Factory.h"
#import "MTDataTableVirtual.h"
#import "MTDataTableFast.h"

@implementation MTDataTable (Factory)

+ (instancetype)dataTableFactory:(NSDictionary *)parameters {
    NSNumber *keyDataTableType = @(MTDataTableTypeOfTable);
    NSNumber *keyDataTableObjectId = @(MTDataTableObjectId);
    NSNumber *keyDataTableNumberOfColumns = @(MTDataTableNumberOfColumns);
    
    NSNumber *dataTableType = parameters[keyDataTableType];
    NSNumber *dataTableObjectId = parameters[keyDataTableObjectId];
    NSNumber *datatableNumberOfColumns = parameters[keyDataTableNumberOfColumns];
    
    NSUInteger numberOfColumns = 0;
    BOOL numberOfColumnsHack = NO;
    BOOL objectIdSet = NO;
    
    id result = nil;
    
    if (datatableNumberOfColumns != nil) {
        numberOfColumnsHack = YES;
        numberOfColumns = [datatableNumberOfColumns integerValue];
    }
    
    //Default type is virtual. If there is no object id, then type MUST be virtual.  That's
    //  because we won't know where to store it.
    MTDataTableType type = MTDataTableTypeVirtual;
    NSUInteger objectId = 0;
    if (dataTableType != nil && dataTableObjectId != nil) {
        type = [dataTableType integerValue];
    }
    
    if (dataTableObjectId != nil) {
        objectIdSet = YES;
        objectId = [dataTableObjectId integerValue];
    }
    
    switch (type) {
        case MTDataTableTypeVirtual: {
            if (objectIdSet) {
                result = [[MTDataTableVirtual alloc] initWithId:objectId];
            } else {
                if (numberOfColumnsHack) {
                    result = [[MTDataTableVirtual alloc] initWithNumberOfColumns:numberOfColumns];
                } else {
                    result = [[MTDataTableVirtual alloc] initWithId:objectId];
                }
            }
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

+ (MTDataTable *)newDataTableForIdentifier:(NSString *)identifier {
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
