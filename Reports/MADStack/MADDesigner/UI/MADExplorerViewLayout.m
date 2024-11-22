//
//  MADGroupedCollectionViewLayout.m
//  MAD
//
//  Created by Michael Thomason on 10/9/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADExplorerViewLayout.h"
#import <MADExplorer/MADCollectionViewCellDocument.h>

@implementation MADExplorerViewLayout

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.estimatedItemSize = CGSizeMake(140.0, 240.0);
	}
	return self;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect; {
	NSArray <UICollectionViewLayoutAttributes *> *attributes = [super layoutAttributesForElementsInRect:rect];
	CGFloat baseline = -2;
	NSMutableArray <UICollectionViewLayoutAttributes *> *sameLineAttributes = [[NSMutableArray alloc] init];
	NSMutableArray <UICollectionViewLayoutAttributes *> *results = [[NSMutableArray alloc] init];
	
	for (UICollectionViewLayoutAttributes *attribute in attributes) {
		if (attribute.representedElementCategory == UICollectionElementCategoryCell) {
			CGFloat centerY = CGRectGetMidY(attribute.frame);
			if (ABS(centerY - baseline) > 1) {
				baseline = centerY;
				if (sameLineAttributes.count > 0) {
					[self alignToTopForSameLineAttributes:sameLineAttributes];
					[results addObjectsFromArray:sameLineAttributes];
					[sameLineAttributes removeAllObjects];
				}
			}
			[sameLineAttributes addObject:attribute];
		}
	}
	
	if (sameLineAttributes.count > 0) {
		[self alignToTopForSameLineAttributes:sameLineAttributes];
		[results addObjectsFromArray:sameLineAttributes];
		[sameLineAttributes removeAllObjects];
	}
	return results;
}

- (void)alignToTopForSameLineAttributes:(NSArray *)sameLineAttributes {
	NSArray *sorted = [sameLineAttributes sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes *attributes1,
																						 UICollectionViewLayoutAttributes *attributes2) {
		CGFloat delta = attributes1.frame.size.height - attributes2.frame.size.height;
		return delta == 0.0 ? NSOrderedSame : ABS(delta)/delta;
	}];
	UICollectionViewLayoutAttributes *tallest = [sorted lastObject];
	CGFloat tallestOriginY = tallest.frame.origin.y;
	[sameLineAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attribute, NSUInteger idx, BOOL *stop) {
		attribute.frame = CGRectOffset(attribute.frame, 0.0, tallestOriginY - attribute.frame.origin.y);
	}];
}

@end
