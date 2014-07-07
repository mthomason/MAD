//
//  MTArrayCached.h
//  MAD
//
//  Created by Michael Thomason on 7/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTArrayCached : NSEnumerator

@property (nonatomic, strong, readonly) NSString *identifier;

- (id)initWithIdentifier:(NSString *)identifier;
- (NSURL *)url;
- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)count;
- (void)addObject:(id)object;
- (void)removeAllObjects;

- (void)beginBulkInserts;
- (void)endBulkInserts;

+ (NSURL *)urlForIdentifier:(NSString *)identifer;

- (void)resetEnumerator;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end
