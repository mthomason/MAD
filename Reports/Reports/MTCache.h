//
//  MTCache.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCache_h
#define Reports_MTCache_h

#import <Foundation/Foundation.h>

@class NSManagedObjectID;

@interface MTCache : NSObject

- (id)initWithString:(NSString *)string;
- (id)initWithTag:(NSUInteger)tag;
- (id)initWithObjectID:(NSManagedObjectID *)objectID;

- (NSArray *)results;
- (void)cacheData:(id)data;

@property (nonatomic, strong, readonly) NSURL *url;

@end

#endif
