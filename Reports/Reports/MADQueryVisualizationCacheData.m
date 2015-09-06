//
//  MADQueryVisualizationCacheData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationCacheData.h"

static NSString * const keyScrollViewContentOffset  = @"1";
static NSString * const keyScrollViewZoomScale      = @"2";
static NSString * const keyTables                   = @"3";

@interface MADQueryVisualizationCacheData ()

    @property (nonatomic, strong, readwrite) NSMutableDictionary *tableDefinations;

@end

@implementation MADQueryVisualizationCacheData

- (instancetype)init {
    if (self = [super init]) {
        NSMutableDictionary *tableDefinations = [[NSMutableDictionary alloc] init];
        self.tableDefinations = tableDefinations;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.scrollViewContentOffset = [aDecoder decodeCGPointForKey:keyScrollViewContentOffset];
        self.scrollViewZoomScale = [aDecoder decodeFloatForKey:keyScrollViewZoomScale];
        NSDictionary *tableDefinations = [aDecoder decodeObjectForKey:keyTables];
        self.tableDefinations = tableDefinations.mutableCopy;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeCGPoint:self.scrollViewContentOffset forKey:keyScrollViewContentOffset];
    [aCoder encodeFloat:self.scrollViewZoomScale forKey:keyScrollViewZoomScale];
    [aCoder encodeObject:self.tableDefinations forKey:keyTables];
}

- (void)addTableDefination:(MADQueryVisulizationTableDefination *)tableDef forObjectID:(NSManagedObjectID *)objectID {
    NSNumber *hash = @(objectID.URIRepresentation.hash);
    self.tableDefinations[hash] = tableDef;
}

- (MADQueryVisulizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID {
    NSNumber *hash = @(objectID.URIRepresentation.hash);
    return self.tableDefinations[hash];
}

@end
