
//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "SectionEnumerator.h"
#import "MTReportDesignerSectionDecorationView.h"
#import "MTCollectionViewLayoutLiquidAttributes.h"
#import "CGGeometry+Extras.h"

@interface MTReportDesignerSectionViewLayoutLiquid ()

@property (nonatomic, assign) NSInteger numberOfSections;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, strong) NSMutableArray *itemAttributesBySection;

@end

@implementation MTReportDesignerSectionViewLayoutLiquid


- (instancetype)init {
    self = [super init];
    if (self) {

        NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] init];
        self.itemAttributesBySection = itemAttributesBySection;

        NSString *decorationViewKind = NSStringFromClass([MTReportDesignerSectionDecorationView class]);
        [self registerClass: [MTReportDesignerSectionDecorationView class]
    forDecorationViewOfKind: decorationViewKind];

    }
    return self;
}

- (NSSet *)positionsOfRects: (CGRect)rect
                 aroundRect: (CGRect)centerRect {
    
    //There exist four potental placement spots for each alredy placed rect
    CGFloat x1 = centerRect.origin.x;
    CGFloat x2 = centerRect.origin.x + centerRect.size.width;
    CGFloat y1 = centerRect.origin.y;
    CGFloat y2 = centerRect.origin.y + centerRect.size.height;
    
    CGRect placement0, placement1, placement2, placement3;
    
    placement0 = CGRectMake(x1, y1, rect.size.width, rect.size.height);
    placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
    placement2 = CGRectMake(x2, y2, rect.size.width, rect.size.height);
    placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);
    
    
    return [NSSet setWithObjects:
            [NSValue valueWithCGRect: placement0],
            [NSValue valueWithCGRect: placement1],
            [NSValue valueWithCGRect: placement2],
            [NSValue valueWithCGRect: placement3], nil];
}

- (NSSet *)availablePositionsOfRect: (CGRect)rect
                         aroundRect: (CGRect)centerRect {
    
    //There exist two potental placement spots around a rect to put another rect.
    
    CGRect placement1 = CGRectMake(centerRect.origin.x + centerRect.size.width,
                                   centerRect.origin.y,
                                   rect.size.width,
                                   rect.size.height);
    
    CGRect placement3 = CGRectMake(centerRect.origin.x,
                                   centerRect.origin.y + centerRect.size.height,
                                   rect.size.width,
                                   rect.size.height);
    
    NSValue *value1 = [NSValue valueWithCGRect: placement1];
    NSValue *value2 = [NSValue valueWithCGRect: placement3];
    return [NSSet setWithObjects:
            value1,
            value2, nil];
}

- (void)prepareLayout {
    [super prepareLayout];
    
    [self.delegate collectionView:self.collectionView prepareLayout:self];
    
    self.numberOfSections = 1;
    self.numberOfItems = [self.delegate numberOfItemsInSection: 0
                                              ofCollectionView: self.collectionView];
}

- (CGSize)collectionViewContentSize {
    return [self.delegate collectionView:self.collectionView sizeForLayout:self];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

    NSArray *layoutAttributes = [self.delegate collectionView: self.collectionView
                                          attributesForLayout: self];
    NSArray *results = @[];
    UICollectionViewLayoutAttributes *itemAttributes;
    for (itemAttributes in layoutAttributes) {
        if (CGRectIntersectsRect(rect, itemAttributes.frame)) {
            results = [results arrayByAddingObject:itemAttributes];
        }
        
    }
    return results;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

    return [self.delegate collectionView:self.collectionView layout:self layoutAttributesForItemAtIndexPath:indexPath];

}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {

    return [self.delegate collectionView:self.collectionView layout:self layoutAttributesForItemAtIndexPath:indexPath];

}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    [self.delegate collectionViewDidFinishUpdates:self.collectionView];
}

- (void)invalidateLayout {
    [super invalidateLayout];
}

@end
