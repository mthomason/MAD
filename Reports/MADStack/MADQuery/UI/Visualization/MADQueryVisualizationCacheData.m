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

@interface MADQueryVisualizationCacheData ()

    @property (nonatomic, strong, readwrite) NSMutableDictionary <NSURL *, MADQueryVisualizationTableDefination *> *tableDefinations;

@end

@implementation MADQueryVisualizationCacheData

static NSString *keyScrollViewContentOffset  = @"1";
static NSString *keyScrollViewZoomScale      = @"2";
static NSString *keyTables                   = @"3";
static NSString *CacheExt                    = @"qvvc";

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
    [aCoder encodeObject:_tableDefinations forKey:keyTables];
}

- (void)addTableDefination:(MADQueryVisualizationTableDefination *)tableDefination
               forObjectID:(NSManagedObjectID *)objectID {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    MADQueryVisualizationTableDefination *copyTableDefination = [tableDefination copyWithZone:nil];
    self.tableDefinations[objectID.URIRepresentation] = copyTableDefination;
}

- (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID {
    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, objectID);
    return self.tableDefinations[objectID.URIRepresentation];
}

- (MADQueryVisualizationTableDefination *)copyTableDefinationForObjectID:(NSManagedObjectID *)objectID {

    MADQueryVisualizationTableDefination *tableDefination;
    tableDefination = [self.tableDefinations objectForKey:objectID.URIRepresentation];
    id copyTableDefination = [tableDefination copyWithZone:nil];
    return copyTableDefination;
}

- (void)removeTableDefinationForObjectID:(NSManagedObjectID *)objectID {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.tableDefinations removeObjectForKey: objectID.URIRepresentation];
}

+ (NSString *)cacheFileNameForFileName:(NSString *)filename {
    NSString *fileName = [NSString stringWithFormat:@"%lu", (unsigned long)filename.hash];
    return [fileName stringByAppendingPathExtension:CacheExt];
}

- (NSString *)debugDescription {
    NSString *debugDescription = [[NSString alloc] initWithFormat:@"%@ <%@>",
                                  NSStringFromClass(self.class),  _tableDefinations];
    return debugDescription;
}

@end
