//
//  MTReportFormatterCache.h
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTReportFormatterCache : NSObject

- (void)setLayout:(id)layout andIndexes:(id)indexes forSize:(CGSize)size;
- (instancetype)init;
- (id)layoutForSize:(CGSize)size;
- (id)indexesForSize:(CGSize)size;
- (void)dumpCache;

@end
