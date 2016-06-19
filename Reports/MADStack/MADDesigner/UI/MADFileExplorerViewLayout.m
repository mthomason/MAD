//
//  MADGroupedCollectionViewLayout.m
//  MAD
//
//  Created by Michael Thomason on 10/9/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerViewLayout.h"

@implementation MADFileExplorerViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    if (attributes == nil) {
        attributes = [[NSArray alloc] init];
    }
    
    NSMutableArray *elementAttributes = [[NSMutableArray alloc] initWithCapacity:attributes.count];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        if (CGRectIntersectsRect(rect, attribute.frame)) {
            [elementAttributes addObject:attribute];
        }
    }
    NSMutableArray *results = [[NSMutableArray alloc] initWithArray:elementAttributes];
    [results addObjectsFromArray:elementAttributes];
   
    return results;
}

@end
