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
#import "UIColor+EverydayApps.h"

@interface MTTableLayout ()
    <UICollectionViewDelegate>


typedef struct _ColumnWidth {
    CGFloat originX, width;
} ColumnWidth;

@property (nonatomic, strong) NSMutableArray *columnWidth;
@property (nonatomic, assign) NSUInteger rowCount;
@property (nonatomic, assign) NSUInteger columnCount;
@property (nonatomic, assign) CGFloat heightRow;
@property (nonatomic, assign) CGFloat heightHeader;

@end

@implementation MTTableLayout


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalizeWithColumnCount:0 andRowCount:0];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initalizeWithColumnCount:0 andRowCount:0];
    }
    return self;
}

- (instancetype)initWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    self = [super init];
    if (self) {
        [self initalizeWithColumnCount:columnCount andRowCount:rowCount];
    }
    return self;
}

- (void)initalizeWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    
    UIEdgeInsets scrollInsets = UIEdgeInsetsMake(88.0000f, CGSizeZero.width, CGSizeZero.height, CGSizeZero.width);
    [self.collectionView setScrollIndicatorInsets: scrollInsets];
    
    NSMutableArray *columnWidths = [NSMutableArray array];
    [self setColumnWidth:columnWidths];
    [self setRowCount:rowCount];
    [self setColumnCount:columnCount];
    [self setHeightRow:22.0000f];
    [self setHeightHeader:24.0000f];
    self.collectionView.delegate = self;
}

- (void)prepareLayout {
    [super prepareLayout];

    NSMutableArray *columnWidths = [[NSMutableArray alloc] initWithCapacity:self.columnCount];
    for (NSInteger i=0; i<self.columnCount; i++) {
        ColumnWidth lastColumnWidth;
        if (i == 0) {
            lastColumnWidth.width = CGSizeZero.width;
            lastColumnWidth.originX = CGPointZero.x;
        } else {
            [[columnWidths lastObject] getValue:&lastColumnWidth];
        }
        ColumnWidth columnWidth;
        columnWidth.originX = lastColumnWidth.originX + lastColumnWidth.width;
        columnWidth.width = [self.delegate collectionView:self.collectionView layout:self widthRequiredColumn:i];
        NSValue *columnWidthEncoding = [NSValue valueWithBytes:&columnWidth objCType:@encode(ColumnWidth)];;
        [columnWidths addObject:columnWidthEncoding];
    }

    [self setColumnWidth:columnWidths];

    if ([self.columnWidth count] > 0) {
        ColumnWidth lastWidth;
        [[self.columnWidth lastObject] getValue:&lastWidth];
        CGFloat tableWidth = lastWidth.originX + lastWidth.width;
        if (tableWidth < self.collectionView.frame.size.width) {
            lastWidth.width = self.collectionView.frame.size.width - lastWidth.originX;
        }
        self.columnWidth[self.columnWidth.count - 1] = [NSValue valueWithBytes:&lastWidth objCType:@encode(ColumnWidth)];
    }

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewLayoutAttributes *supplementalAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"MTTableCellHeader" withIndexPath:indexPath];
    NSUInteger column = indexPath.row;
    CGRect frame = [self locationOfHeaderAtColumn:column];
    [supplementalAttributes setFrame:frame];
    [supplementalAttributes setHidden:NO];
    [supplementalAttributes setZIndex:999];
    [supplementalAttributes setAlpha:0.9000f];
    return supplementalAttributes;
}

- (NSUInteger)columnForIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row % [self columnCount];
}
- (NSUInteger)rowForIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row / [self columnCount];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger column = [self columnForIndexPath:indexPath];
    NSUInteger row = [self rowForIndexPath:indexPath];
    CGRect elementFrame = [self locationOfObjectAtRow:row andColumn:column];
    UICollectionViewLayoutAttributes *elementAttributes = [self layoutAttributesForItemAtRow:row andColumn:column withFrame:elementFrame];
    return elementAttributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    
    //Change bounds so that the origin is positive.  Not drawing this offscreen.
    if (CGPointZero.x + rect.origin.x < CGPointZero.x) {
        rect.size.width += (CGPointZero.x + rect.origin.x);
        rect.origin.x = CGPointZero.x;
    }
    if (CGPointZero.y + rect.origin.y < CGPointZero.y) {
        rect.size.height += (CGPointZero.y + rect.origin.y);
        rect.origin.y = CGPointZero.y;
    }
    CGFloat originRightEdge = rect.origin.x + rect.size.width;
    
    NSInteger firstColumn = 0;
    NSUInteger columnsToDisplay = 0;    //Columns are calculated.
    NSUInteger columnCounter = 0;
    BOOL foundFirstColumn = NO;
    for (NSValue *v in [self columnWidth]) {
        ColumnWidth cw;
        [v getValue:&cw];
        if (foundFirstColumn == NO) {
            if (cw.originX > rect.origin.x) {
                firstColumn = (columnCounter == 0) ? 0 : columnCounter - 1;
                foundFirstColumn = YES;
            } else if (cw.originX == rect.origin.x) {
                firstColumn = columnCounter;
                foundFirstColumn = YES;
            }
        }
        if (foundFirstColumn) {
            if (cw.originX >= originRightEdge) {
                NSUInteger lastColumn = columnCounter;
                columnsToDisplay = lastColumn - firstColumn + 1;
                break;
            }
        }
        columnCounter++;
    }
    
    if (columnsToDisplay == 0 &&
        [self originXColumnLast] <= rect.origin.x + rect.size.width) {
        columnsToDisplay = [[self columnWidth] count];
    }
    
    
    NSUInteger rowsToDisplay = ceil(rect.size.height / self.heightRow); //Rows are fixed height.
    
    if (rowsToDisplay > self.rowCount) rowsToDisplay = self.rowCount;
    if (columnsToDisplay > self.columnCount) columnsToDisplay = self.columnCount;
    
    NSInteger firstRow = abs((CGPointZero.y - rect.origin.y)  / self.heightRow);
    
    if (firstRow > self.rowCount) firstRow = self.rowCount;
    if (firstColumn > self.columnCount) firstColumn = self.columnCount;
    
    NSUInteger lastColumn = columnsToDisplay + firstColumn;
    if (lastColumn > self.columnCount) lastColumn = self.columnCount;
    for (NSUInteger colCounter=firstColumn; colCounter < lastColumn; colCounter++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:colCounter inSection:0];
        UICollectionViewLayoutAttributes *supplementalAttributes = [self layoutAttributesForSupplementaryViewOfKind:@"MTTableCellHeader" atIndexPath:indexPath];
        [layoutAttributes addObject:supplementalAttributes];
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
        }
    }
    
    return layoutAttributes;
}

- (CGSize)collectionViewContentSize {
    CGFloat width = [self originXColumnLast] + [self widthColumnLast];
    CGFloat height = (self.heightRow * self.rowCount) + self.heightHeader;
    return CGSizeMake(width, height);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds { return YES; }

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

- (CGFloat)originXColumn:(NSUInteger)column {
    ColumnWidth cw = [self columnAttributesAtIndex:column];
    return cw.originX;
}

- (CGFloat)widthColumn:(NSUInteger)column {
    ColumnWidth cw = [self columnAttributesAtIndex:column];
    return cw.width;
}

- (CGFloat)widthColumnLast {
    ColumnWidth cw;
    [[[self columnWidth] lastObject] getValue:&cw];
    return cw.width;
}

- (CGFloat)originXColumnLast {
    ColumnWidth cw;
    [[[self columnWidth] lastObject] getValue:&cw];
    return cw.originX;
}

- (ColumnWidth)columnAttributesAtIndex:(NSUInteger)column {
    ColumnWidth cw;
    [[self columnWidth][column] getValue:&cw];
    return cw;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtRow:(NSUInteger)row andColumn:(NSUInteger)column {
    CGFloat x = [self originXColumn:column];
    CGFloat y = self.heightRow * row;
    CGFloat w = [self widthColumn:column];
    CGFloat h = self.heightRow;
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

+ (id)fillArray:(NSMutableArray *)array withObject:(id)object numberOfTimes:(NSUInteger)count {
    [array removeAllObjects];
    for (NSUInteger i=0; i<count; i++) array[i] = object;
    return array;
}

- (CGRect)locationOfHeaderAtColumn:(NSUInteger)column {
    CGFloat x = [self originXColumn:column];
    CGFloat y = (self.collectionView.contentOffset.y < - self.collectionView.contentInset.top) ?
                    CGPointZero.y :
                    CGPointZero.y + self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
    CGFloat w = [self widthColumn:column];
    CGFloat h = self.heightHeader;
    return CGRectMake(x, y, w, h);
}

- (CGRect)locationOfObjectAtRow:(NSUInteger)row andColumn:(NSUInteger)column {
    CGFloat x = [self originXColumn:column];
    CGFloat y = CGPointZero.y + self.heightHeader + (row * self.heightRow);
    CGFloat w = [self widthColumn:column];
    CGFloat h = self.heightRow;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self invalidateLayout];
}

@end
