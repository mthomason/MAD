//
//  MADQueryVisualizationCacheData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationCacheData.h"
#import "MADQueryVisualizationTableDefination.h"
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADAppDelegate.h>
#import <CoreData/NSManagedObjectID.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSURL.h>
#import <UIKit/UIGeometry.h>

static NSString * const keyScrollViewContentOffset  = @"1";
static NSString * const keyScrollViewZoomScale      = @"2";
static NSString * const keyTables                   = @"3";
static NSString * const CacheExt                    = @"qvvc";

@interface MADQueryVisualizationCacheData ()

    @property (nonatomic, strong, readwrite) NSMutableDictionary *tableDefinations;

@end

@implementation MADQueryVisualizationCacheData

- (void)dealloc { }

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

- (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDefination
               forObjectID:(NSManagedObjectID *)objectID {
    NSURL *uriRepresentation = [objectID URIRepresentation];
    id stringRepresention = uriRepresentation.absoluteString;
    MADQueryVisualizationTableDefination *copyTableDefination = [tableDefination copyWithZone:nil];
    self.tableDefinations[stringRepresention] = copyTableDefination;
}

- (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID {
    NSURL *uriRepresentation = [objectID URIRepresentation];
    id stringRepresention = uriRepresentation.absoluteString;
    return self.tableDefinations[stringRepresention];
}

- (MADQueryVisualizationTableDefination *)copyTableDefinationForObjectID:(NSManagedObjectID *)objectID {
    NSURL *uriRepresentation = [objectID URIRepresentation];
    id stringRepresention = uriRepresentation.absoluteString;
    MADQueryVisualizationTableDefination *tableDefination = self.tableDefinations[stringRepresention];
    id copyTableDefination = [tableDefination copyWithZone:nil];
    return copyTableDefination;
}

- (void)removeTableDefinationForObjectID:(NSManagedObjectID *)objectID {
    [self.tableDefinations removeObjectForKey:objectID.URIRepresentation.absoluteString];
}

+ (NSString *)cacheFileNameForFileName:(NSString *)filename {
    NSString *fileName = [NSString stringWithFormat:@"%lu", (unsigned long)filename.hash];
    return [fileName stringByAppendingPathExtension:CacheExt];
}

@end
