//
//  MADQueryVisualizationCacheData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationCacheData.h"
#import <Foundation/NSCoder.h>
#import <UIKit/UIGeometry.h>

static NSString * const keyScrollViewContentOffset  = @"1";
static NSString * const keyScrollViewZoomScale      = @"2";
static NSString * const keyTables                   = @"3";

@interface MADQueryVisualizationCacheData ()

    @property (nonatomic, strong, readwrite) NSMutableDictionary *tableDefinations;

@end

@implementation MADQueryVisualizationCacheData

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

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
        self.scrollViewZoomScale = (CGFloat)[aDecoder decodeDoubleForKey:keyScrollViewZoomScale];
        NSDictionary *tableDefinations = [aDecoder decodeObjectForKey:keyTables];
        self.tableDefinations = tableDefinations.mutableCopy;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeCGPoint:self.scrollViewContentOffset forKey:keyScrollViewContentOffset];
    [aCoder encodeDouble:self.scrollViewZoomScale forKey:keyScrollViewZoomScale];
    [aCoder encodeObject:self.tableDefinations forKey:keyTables];
}

- (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDef forObjectID:(NSManagedObjectID *)objectID {
    self.tableDefinations[objectID.URIRepresentation.absoluteString] = tableDef;
}

- (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID {
    return self.tableDefinations[objectID.URIRepresentation.absoluteString];
}

@end
