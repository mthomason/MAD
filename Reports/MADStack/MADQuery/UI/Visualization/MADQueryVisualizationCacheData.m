//
//  MADQueryVisualizationCacheData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationCacheData.h"
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADAppDelegate.h>
#import <CoreData/NSManagedObjectID.h>

static NSString * const keyScrollViewContentOffset  = @"1";
static NSString * const keyScrollViewZoomScale      = @"2";
static NSString * const keyTables                   = @"3";
static NSString * const CacheExt                    = @"qvvc";

@interface MADQueryVisualizationCacheData ()

    @property (nonatomic, strong, readwrite) NSMutableDictionary *tableDefinations;

@end

@implementation MADQueryVisualizationCacheData

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithNumberOfTables:(NSUInteger)countTables {
    if (self = [super init]) {
        id tableDefinations = [[NSMutableDictionary alloc] initWithCapacity:countTables];
        self.tableDefinations = tableDefinations;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.scrollViewContentOffset = [aDecoder decodeCGPointForKey:keyScrollViewContentOffset];
        self.scrollViewZoomScale = (CGFloat)[aDecoder decodeDoubleForKey:keyScrollViewZoomScale];
        NSDictionary *tableDefinations = [aDecoder decodeObjectForKey:keyTables];
        self.tableDefinations = [[NSMutableDictionary alloc] initWithDictionary: tableDefinations];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeCGPoint:_scrollViewContentOffset forKey:keyScrollViewContentOffset];
    [aCoder encodeDouble:_scrollViewZoomScale forKey:keyScrollViewZoomScale];

    NSDictionary *tableDefinations = self.tableDefinations.copy;
    [aCoder encodeObject:tableDefinations forKey:keyTables];
}

- (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDef forObjectID:(NSManagedObjectID *)objectID {
    self.tableDefinations[objectID.URIRepresentation.absoluteString] = tableDef;
}

- (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID {
    return self.tableDefinations[objectID.URIRepresentation.absoluteString];
}

- (void)removeTableDefinationForObjectID:(NSManagedObjectID *)objectID {
    [self.tableDefinations removeObjectForKey:objectID.URIRepresentation.absoluteString];
}

+ (NSString *)cacheFileNameForFileName:(NSString *)filename {
    NSString *fileName = [NSString stringWithFormat:@"%lu", (unsigned long)filename.hash];
    return [fileName stringByAppendingPathExtension:CacheExt];
}

@end
