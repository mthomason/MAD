
//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "MTReportDesignerSectionDecorationView.h"
//#import "MTCollectionViewLayoutLiquidAttributes.h"

static inline CGRect rectAvailablePosition1(CGRect rect, CGRect centerRect);
static inline CGRect rectAvailablePosition1(CGRect rect, CGRect centerRect) {
    return CGRectMake(centerRect.origin.x + centerRect.size.width,
                      centerRect.origin.y,
                      rect.size.width,
                      rect.size.height);
}

static inline CGRect rectAvailablePosition2(CGRect rect, CGRect centerRect);
static inline CGRect rectAvailablePosition2(CGRect rect, CGRect centerRect) {
    return CGRectMake(centerRect.origin.x,
                      centerRect.origin.y + centerRect.size.height,
                      rect.size.width,
                      rect.size.height);
}

@interface MTReportDesignerSectionViewLayoutLiquid ()

@property (nonatomic, assign) NSUInteger numberOfSections;
@property (nonatomic, assign) NSUInteger numberOfItems;
@property (nonatomic, strong) NSMutableArray *itemAttributesBySection;

@end

@implementation MTReportDesignerSectionViewLayoutLiquid

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] init];
    self.itemAttributesBySection = itemAttributesBySection;
    
    NSString *decorationViewKind = NSStringFromClass([MTReportDesignerSectionDecorationView class]);
    [self registerClass: [MTReportDesignerSectionDecorationView class]
forDecorationViewOfKind: decorationViewKind];


    return self;
}

+ (NSSet *)positionsOfRects: (CGRect)rect
                 aroundRect: (CGRect)centerRect {
    
    NSSet *placements;
    CGRect placement0, placement1, placement2, placement3;
    NSValue *placement0v, *placement1v, *placement2v, *placement3v;

    //There exist four potental placement spots for each alredy placed rect
    CGFloat x1 = centerRect.origin.x;
    CGFloat x2 = centerRect.origin.x + centerRect.size.width;
    CGFloat y1 = centerRect.origin.y;
    CGFloat y2 = centerRect.origin.y + centerRect.size.height;
    
    placement0 = CGRectMake(x1, y1, rect.size.width, rect.size.height);
    placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
    placement2 = CGRectMake(x2, y2, rect.size.width, rect.size.height);
    placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);
    
    placement0v = [NSValue valueWithCGRect: placement0];
    placement1v = [NSValue valueWithCGRect: placement1];
    placement2v = [NSValue valueWithCGRect: placement2];
    placement3v = [NSValue valueWithCGRect: placement3];
    
    placements = [[NSSet alloc] initWithObjects:placement0v, placement1v,
                                                placement2v, placement3v, nil];
    
    return placements;
}

+ (NSSet <NSValue *> *)availablePositionsOfRect: (CGRect)rect
                                     aroundRect: (CGRect)centerRect {
    
    //There exist two potental placement spots around a rect to put another rect.
    id value1 = [NSValue valueWithCGRect: rectAvailablePosition1(rect, centerRect)];
    id value2 = [NSValue valueWithCGRect: rectAvailablePosition2(rect, centerRect)];
    NSSet *result = [[NSSet alloc] initWithObjects:value1, value2, nil];
    return result;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    id <MTReportDesignerSectionViewLayoutLiquidDelegate, UICollectionViewDataSource> delegate;
    delegate = self.delegate;
    [delegate collectionView:self.collectionView prepareLayout:self];
    
    self.numberOfSections = 1;
    self.numberOfItems = delegate != nil ? [delegate numberOfItemsInSection: 0
                                                           ofCollectionView: self.collectionView] :
                                                           0;
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

- (MADSectionLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

    id <MTReportDesignerSectionViewLayoutLiquidDelegate, UICollectionViewDataSource> delegate;
    delegate = self.delegate;
    id attributes = [delegate collectionView: self.collectionView
                                      layout: self
          layoutAttributesForItemAtIndexPath: indexPath];
    return attributes;

}

- (MADSectionLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:
                                                                        (NSIndexPath *)indexPath {

    id <MTReportDesignerSectionViewLayoutLiquidDelegate, UICollectionViewDataSource> delegate;
    delegate = self.delegate;
    id attributes = [delegate collectionView: self.collectionView
                                      layout: self
          layoutAttributesForItemAtIndexPath: indexPath];
    return attributes;

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
