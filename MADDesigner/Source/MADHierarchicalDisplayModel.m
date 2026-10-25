//
//  MADQueryVisualizationCacheData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/5/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADHierarchicalDisplayModel.h"
#import "MADHierarchicalChildViewDefination.h"
#import <MADFoundation/MADApplicationProtocol.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSURL.h>
#import <UIKit/UIGeometry.h>

static NSString *keyScrollViewContentOffset  = @"1";
static NSString *keyScrollViewZoomScale      = @"2";
static NSString *keyTables                   = @"3";
static NSString *CacheExt                    = @"qvvc";

@interface MADHierarchicalDisplayModel ()
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSNumber *, MADHierarchicalChildViewDefination *> *tableDefinations;
@end

@implementation MADHierarchicalDisplayModel

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (void)dealloc { }

- (instancetype)initWithNumberOfTables:(NSUInteger)countTables {
	if (self = [super init]) {
		NSMutableDictionary <NSNumber *, MADHierarchicalChildViewDefination *> *tableDefinations = [[NSMutableDictionary alloc] initWithCapacity:countTables];
		self.tableDefinations = tableDefinations;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.scrollViewContentOffset = [aDecoder decodeCGPointForKey:keyScrollViewContentOffset];
		self.scrollViewZoomScale = (CGFloat)[aDecoder decodeDoubleForKey:keyScrollViewZoomScale];
		NSSet *classes = [[NSSet alloc] initWithObjects:[NSMutableDictionary class], [NSDictionary class], [NSNumber class], [MADHierarchicalChildViewDefination class], nil];
		self.tableDefinations = [[aDecoder decodeObjectOfClasses:classes forKey:keyTables] mutableCopy];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeCGPoint:_scrollViewContentOffset forKey:keyScrollViewContentOffset];
	[aCoder encodeDouble:_scrollViewZoomScale forKey:keyScrollViewZoomScale];
	[aCoder encodeObject:_tableDefinations forKey:keyTables];
}

- (void)addTableDefination:(MADHierarchicalChildViewDefination *)tableDefination forObjectID:(int64_t)objectID {
	MADHierarchicalChildViewDefination *copyTableDefination = [tableDefination copyWithZone:nil];
	self.tableDefinations[@(objectID)] = copyTableDefination;
}

- (MADHierarchicalChildViewDefination *)tableDefinationForObjectID:(int64_t)objectID {
	return self.tableDefinations[@(objectID)];
}

- (void)removeTableDefinationForObjectID:(int64_t)objectID {
	[self.tableDefinations removeObjectForKey: @(objectID)];
}

+ (NSString *)cacheFileNameForFileName:(NSString *)filename {
	return [[NSString stringWithFormat:@"%lu", (unsigned long)filename.hash] stringByAppendingPathExtension:CacheExt];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ <%@>", NSStringFromClass(self.class),  _tableDefinations];
}

@end
