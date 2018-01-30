//
//  MADGroupedCollectionViewLayout.m
//  MAD
//
//  Created by Michael Thomason on 10/9/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerViewLayout.h"
#import <MADExplorer/MADCollectionViewCellDocument.h>

@implementation MADExplorerViewLayout

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    }
    return self;
}

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

    return elementAttributes;
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    /*typeof(self) __weak weakself = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakself.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[MADCollectionViewCellDocument class]]) {
                    if (((MADCollectionViewCellDocument *)obj).isWobbling) {
                        ((MADCollectionViewCellDocument *)obj).wobbling = NO;
                        ((MADCollectionViewCellDocument *)obj).wobbling = YES;
                    }
                }
            }];
        });
    });*/
}

@end
