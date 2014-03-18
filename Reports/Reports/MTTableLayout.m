//
//  MTTableLayout.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableLayout.h"

@interface MTTableLayout ()

@property (nonatomic, retain) NSArray *columnWidth;
@property (nonatomic, retain) NSArray *rowHeight;

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

- (CGSize)collectionViewContentSize {
    CGFloat width = [MTTableLayout sumArrayOfFloats:self.columnWidth];
    CGFloat height = [MTTableLayout sumArrayOfFloats:self.rowHeight];
    return CGSizeMake(width, height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

    __block NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];

    block_enumerateObjectsUsingBlock addColumns = ^(id obj, NSUInteger section, BOOL *stop) {
    
        block_enumerateObjectsUsingBlock addRows = ^(id obj, NSUInteger row, BOOL *stop) {
            NSIndexPath *elementPath = [NSIndexPath indexPathForRow:row inSection:section];
            CGRect elementFrame = [self locationOfObjectAtIndexPath:elementPath];
            BOOL intersection = CGRectIntersectsRect(elementFrame, rect);
            if (intersection) {
                UICollectionViewLayoutAttributes *elementAttributes = [self layoutAttributesForItemAtIndexPath:elementPath withFrame:elementFrame];
                [layoutAttributes addObject:elementAttributes];
            }
        };
        [[self rowHeight] enumerateObjectsUsingBlock:addRows];
    };
    [[self columnWidth] enumerateObjectsUsingBlock:addColumns];
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat x = [MTTableLayout sumArrayOfFloats:self.columnWidth toIndex:indexPath.section];
    CGFloat y = [MTTableLayout sumArrayOfFloats:self.rowHeight toIndex:indexPath.row];
    CGFloat w = [self.columnWidth[indexPath.section] floatValue];
    CGFloat h = [self.rowHeight[indexPath.section] floatValue];
    CGRect f = CGRectMake(x, y, w, h);
    return [self layoutAttributesForItemAtIndexPath:indexPath withFrame:f];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds { return NO; }

#pragma mark - Public methods

- (void)setColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    if (columnCount != self.columnWidth.count ||
        columnCount != self.rowHeight.count) {
        [self initalizeWithColumnCount:columnCount andRowCount:rowCount];
        [self invalidateLayout];
    }
}

#pragma mark - Helpers

- (void)initalizeWithColumnCount:(NSUInteger)columnCount andRowCount:(NSUInteger)rowCount {
    NSArray *columnWidths = [MTTableLayout defaultColumWidthsForCount:columnCount];
    NSArray *rowHeights = [MTTableLayout defaultRowHeightsForCount:rowCount];
    [self setColumnWidth:columnWidths];
    [self setRowHeight:rowHeights];
}

+ (NSArray *)defaultColumWidthsForCount:(NSUInteger)columnConter {
    NSMutableArray *columnWidth = [[NSMutableArray alloc] initWithCapacity:columnConter];
    return [self fillArray:columnWidth withObject:@(75.0000f) numberOfTimes:columnConter];
}

+ (NSArray *)defaultRowHeightsForCount:(NSUInteger)rowCounter {
    NSMutableArray *rowHeights = [[NSMutableArray alloc] initWithCapacity:rowCounter];
    return [self fillArray:rowHeights withObject:@(22.0000f) numberOfTimes:rowCounter];
}

+ (id)fillArray:(NSMutableArray *)array withObject:(id)object numberOfTimes:(NSUInteger)count {
    [array removeAllObjects];
    for (NSUInteger i=0; i<count; i++) array[i] = object;
    return array;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath withFrame:(CGRect)frame {
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    [layoutAttributes setFrame:frame];
    [layoutAttributes setAlpha:1.0000f];
    return layoutAttributes;
}

- (CGRect)locationOfObjectAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat x = [MTTableLayout sumArrayOfFloats:self.columnWidth toIndex:indexPath.section];
    CGFloat y = [MTTableLayout sumArrayOfFloats:self.rowHeight toIndex:indexPath.row];
    CGFloat w = [self.columnWidth[indexPath.section] floatValue];
    CGFloat h = [self.columnWidth[indexPath.section] floatValue];
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

@end
