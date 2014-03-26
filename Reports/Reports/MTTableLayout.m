//
//  MTTableLayout.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableLayout.h"

@interface MTTableLayout ()

@property (nonatomic, retain) NSArray *columnWidth;
@property (nonatomic, assign) NSUInteger rowCount;
@property (nonatomic, assign) NSUInteger columnCount;
@property (nonatomic, assign) CGFloat rowHeight;

@end

@implementation MTTableLayout


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalizeWithColumnCount:0 andRowCount:0];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initalizeWithColumnCount:0 andRowCount:0];
    }
    return self;
}

- (id)initWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    self = [super init];
    if (self) {
        [self initalizeWithColumnCount:columnCount andRowCount:rowCount];
    }
    return self;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewLayoutAttributes *supplementalAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"MTTableCellHeader" withIndexPath:indexPath];
    NSUInteger column = indexPath.row;
    CGRect frame = [self locationOfHeaderAtColumn:column];
    [supplementalAttributes setFrame:frame];
    [supplementalAttributes setHidden:NO];
    [supplementalAttributes setAlpha:1.0000f];
    return supplementalAttributes;
}
/*
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)decorationViewKind
                                                                  atIndexPath:(NSIndexPath *)indexPath {
    
}*/

- (NSUInteger)columnForIndexPath:(NSIndexPath *)indexPath {
    return [indexPath row] % [self columnCount];
}
- (NSUInteger)rowForIndexPath:(NSIndexPath *)indexPath {
    return [indexPath row] / [self columnCount];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger column = [self columnForIndexPath:indexPath];
    NSUInteger row = [self rowForIndexPath:indexPath];
    CGRect elementFrame = [self locationOfObjectAtRow:row andColumn:column];
    UICollectionViewLayoutAttributes *elementAttributes = [self layoutAttributesForItemAtRow:row andColumn:column withFrame:elementFrame];
    return elementAttributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    //NSLog(@"rect: %@", NSStringFromCGRect(rect));
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    
    //Change bounds so that the origin is positive.  Not drawing this offscreen.
    
    if (CGPointZero.x + rect.origin.x < CGPointZero.x) {
        rect.size.width += (CGPointZero.x + rect.origin.x);
        rect.origin.x = CGPointZero.x;
        //NSLog(@"crop rect: %@", NSStringFromCGRect(rect));
    }
    
    if (CGPointZero.y + rect.origin.y < CGPointZero.y) {
        rect.size.height += (CGPointZero.y + rect.origin.y);
        rect.origin.y = CGPointZero.y;
        //NSLog(@"crop rect: %@", NSStringFromCGRect(rect));
    }
    
    NSUInteger rowsToDisplay = ceil(rect.size.height / self.rowHeight);
    NSUInteger columnsToDisplay = ceil( rect.size.width / 75.0000f);
    
    if (rowsToDisplay > self.rowCount) rowsToDisplay = self.rowCount;
    if (columnsToDisplay > self.columnCount) columnsToDisplay = self.columnCount;
    
    NSInteger firstRow = abs((CGPointZero.y - rect.origin.y)  / self.rowHeight);
    NSInteger firstColumn = abs((CGPointZero.x - rect.origin.x)  / 75.0000f);
    
    if (firstRow > self.rowCount) firstRow = self.rowCount;
    if (firstColumn > self.columnCount) firstColumn = self.columnCount;
    
    NSUInteger lastColumn = columnsToDisplay + firstColumn;
    if (lastColumn > self.columnCount) lastColumn = self.columnCount;
    for (NSUInteger colCounter=firstColumn; colCounter < lastColumn; colCounter++) {
        CGRect cellHeaderRect = [self locationOfHeaderAtColumn:colCounter];
        if (CGRectIntersectsRect(rect, cellHeaderRect)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:colCounter inSection:0];
            UICollectionViewLayoutAttributes *supplementalAttributes = [self layoutAttributesForSupplementaryViewOfKind:@"MTTableCellHeader" atIndexPath:indexPath];
            CGRect frame = [self locationOfHeaderAtColumn:colCounter];
            [supplementalAttributes setFrame:frame];
            [supplementalAttributes setHidden:NO];
            [supplementalAttributes setAlpha:1.0000f];
            [layoutAttributes addObject:supplementalAttributes];
        }
    }


    
    NSUInteger lastRow = rowsToDisplay + firstRow;
    if (lastRow > self.rowCount) lastRow = self.rowCount;
    for (NSUInteger rowCounter = firstRow; rowCounter < lastRow; rowCounter++) {
        lastColumn = columnsToDisplay + firstColumn;
        if (lastColumn > self.columnCount) lastColumn = self.columnCount;
        for (NSUInteger colCounter=firstColumn; colCounter < lastColumn; colCounter++) {
            CGRect elementFrame = [self locationOfObjectAtRow:rowCounter andColumn:colCounter];
            UICollectionViewLayoutAttributes *elementAttributes = [self layoutAttributesForItemAtRow:rowCounter andColumn:colCounter withFrame:elementFrame];
            [layoutAttributes addObject:elementAttributes];
            //NSLog(@"elem[%ld]: %@", (long)elementAttributes.indexPath.row, NSStringFromCGRect(elementAttributes.frame));
            
        }
    }
    
    return layoutAttributes;
}

- (CGSize)collectionViewContentSize {
    CGFloat width = [MTTableLayout sumArrayOfFloats:self.columnWidth];
    CGFloat height = (self.rowHeight * self.rowCount) + 22.0000f;
    return CGSizeMake(width, height);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds { return NO; }

- (void)invalidateLayout {
    [super invalidateLayout];
}

#pragma mark - Public methods

- (void)setColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    if (columnCount != self.columnWidth.count) {
        [self initalizeWithColumnCount:columnCount andRowCount:rowCount];
    }
    [self invalidateLayout];
}

#pragma mark - Helpers

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtRow:(NSUInteger)row andColumn:(NSUInteger)column {
    CGFloat x = powf(75.0000f, column);
    CGFloat y = self.rowHeight * row;
    CGFloat w = 75.0000f;
    CGFloat h = self.rowHeight;
    CGRect f = CGRectMake(x, y, w, h);
    return [self layoutAttributesForItemAtRow:(NSUInteger)row andColumn:(NSUInteger)column withFrame:f];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtRow:(NSUInteger)row andColumn:(NSUInteger)column withFrame:(CGRect)frame {
    NSInteger index = (row*self.columnCount)+column;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    [layoutAttributes setFrame:frame];
    [layoutAttributes setAlpha:1.0000f];
    return layoutAttributes;
}

- (void)initalizeWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    NSArray *columnWidths = [MTTableLayout defaultColumWidthsForCount:columnCount];
    [self setColumnWidth:columnWidths];
    [self setRowCount:rowCount];
    [self setColumnCount:columnCount];
    [self setRowHeight:22.0000f];
}

+ (NSArray *)defaultColumWidthsForCount:(NSUInteger)columnConter {
    NSMutableArray *columnWidth = [[NSMutableArray alloc] initWithCapacity:columnConter];
    return [self fillArray:columnWidth withObject:@(75.0000f) numberOfTimes:columnConter];
}


+ (id)fillArray:(NSMutableArray *)array withObject:(id)object numberOfTimes:(NSUInteger)count {
    [array removeAllObjects];
    for (NSUInteger i=0; i<count; i++) array[i] = object;
    return array;
}

- (CGRect)locationOfHeaderAtColumn:(NSUInteger)column {
    CGFloat x = CGPointZero.x + (column * 75.0000f);
    CGFloat y = CGPointZero.y;
    CGFloat w = 75.0000f;
    CGFloat h = 22.0000f;
    return CGRectMake(x, y, w, h);
}

- (CGRect)locationOfObjectAtRow:(NSUInteger)row andColumn:(NSUInteger)column {
    CGFloat x = CGPointZero.x + (column * 75.0000f);
    CGFloat y = CGPointZero.y + 22.0000f + (row * 22.0000f);
    CGFloat w = 75.0000f;
    CGFloat h = 22.0000f;
    return CGRectMake(x, y, w, h);
}

+ (CGFloat)sumArrayOfFloats:(NSArray *)array {
    __block CGFloat sum = 0.0000f;
    block_enumerateObjectsUsingBlock blockSumFloats = ^(id obj, NSUInteger idx, BOOL *stop) {
        sum += [obj floatValue];
    };
    [array enumerateObjectsUsingBlock:blockSumFloats];
    return sum;
}

+ (CGFloat)sumArrayOfFloats:(NSArray *)array toIndex:(NSUInteger)stopPoint {
    __block CGFloat sum = 0.0000f;
    block_enumerateObjectsUsingBlock blockSumFloats = ^(id obj, NSUInteger idx, BOOL *stop) {
        sum += [obj floatValue];
        if (idx == stopPoint) *stop = YES;
    };
    [array enumerateObjectsUsingBlock:blockSumFloats];
    return sum;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section {
    return section == 0 ? self.columnWidth.count * self.rowCount : 0;
}

@end
