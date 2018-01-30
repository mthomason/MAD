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

    NSArray <UICollectionViewLayoutAttributes *> *attributes;
    attributes = [super layoutAttributesForElementsInRect:rect];
    if (attributes == nil) {
        attributes = [[NSArray alloc] init];
    }
    
    NSMutableArray *elementAttributes = [[NSMutableArray alloc] initWithCapacity:attributes.count];

    CGFloat lastY = attributes.firstObject.frame.origin.y;
    CGFloat lastHeight = attributes.firstObject.frame.size.height;
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        if (CGRectIntersectsRect(rect, attribute.frame)) {
            if (attribute.frame.size.height < lastHeight) {
                lastHeight = attribute.frame.size.height;
            }
            if (attribute.frame.origin.y > lastY + lastHeight) {
                lastY = attribute.frame.origin.y;
            }
            attribute.frame = CGRectMake(attribute.frame.origin.x, lastY,
                                         attribute.frame.size.width, attribute.frame.size.height);
            
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
