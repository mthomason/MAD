//
//  MTReportFormatterCache.h
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTReportFormatterCache : NSObject

- (void)setLayout:(NSArray *)layout andIndexes:(NSArray *)indexes forSize:(CGSize)size;
- (NSArray *)layoutForSize:(CGSize)size;
- (NSArray *)indexesForSize:(CGSize)size;
- (void)dumpCache;

@end
