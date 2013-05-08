
//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionViewLayoutLiquid.h"

@interface MTReportDesignerSectionViewLayoutLiquid ()

@property (assign) CGSize contentSize;
@property (assign) NSInteger numberOfSections;

@property (nonatomic, retain) NSMutableArray *itemAttributesBySection;
@property (nonatomic, retain) NSMutableArray *decorationAttributesBySection;
@property (nonatomic, retain) NSMutableArray *invalidatedLayoutArray;

@property (nonatomic, retain) NSMutableArray *placedItemDropPoint;
@property (nonatomic, retain) NSMutableArray *placedItemFrame;
@property (nonatomic, assign) NSUInteger totalNumberOfItems;

@end

@implementation MTReportDesignerSectionViewLayoutLiquid

- (void)dealloc {
    [_itemAttributesBySection release];
    [_decorationAttributesBySection release];
    [_invalidatedLayoutArray release];
    [_placedItemDropPoint release];
    [_placedItemFrame release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] init];
        [self setItemAttributesBySection:itemAttributesBySection];
        [itemAttributesBySection release];
        
        NSMutableArray *placedItemDropPoint = [[NSMutableArray alloc] init];
        [self setPlacedItemDropPoint:placedItemDropPoint];
        [placedItemDropPoint release];

        NSMutableArray *placedItemFrame = [[NSMutableArray alloc] init];
        [self setPlacedItemFrame:placedItemFrame];
        [placedItemFrame release];

        [self registerClass: [MTReportDesignerSectionDecorationView class]
    forDecorationViewOfKind: NSStringFromClass([MTReportDesignerSectionDecorationView class])];

    }
    return self;
}

/*- (BOOL)doesRect:(CGRect)rect overlapWithAnother:(NSArray *)placedRects {
    BOOL result = NO;
    for (NSValue *rectValue in placedRects) {
        CGRect placedRect = [rectValue CGRectValue];
        if (CGRectIntersectsRect(rect, placedRect)) {
            result = YES;
            break;
        }
    }
}*/

- (MTCollectionViewLayoutLiquidAttributes *)placeLayouts:(NSArray *)layoutAttributesForSection forLayout:(MTCollectionViewLayoutLiquidAttributes *)layout {

    CGFloat distanceFromDropPoint = -1.0000f;   //Represents an invalid distance
    CGRect nearestRect;
    
    for (MTCollectionViewLayoutLiquidAttributes *placedLayout in layoutAttributesForSection) {
        
        //There exist four potental placement spots for each alredy placed rect
        CGFloat x1 = placedLayout.frame.origin.x;
        CGFloat x2 = placedLayout.frame.origin.x + placedLayout.frame.size.width;
        CGFloat y1 = placedLayout.frame.origin.y;
        CGFloat y2 = placedLayout.frame.origin.y + placedLayout.frame.size.height;
        
        CGRect placement0, placement1, placement2, placement3;
        
        placement0 = CGRectMake(x1, y1, layout.frame.size.width, layout.frame.size.height);
        placement1 = CGRectMake(x2, y1, layout.frame.size.width, layout.frame.size.height);
        placement2 = CGRectMake(x2, y2, layout.frame.size.width, layout.frame.size.height);
        placement3 = CGRectMake(x1, y2, layout.frame.size.width, layout.frame.size.height);
        
        //BOOL validPoint;
        
        NSArray *potentialPlacements = @[[NSValue valueWithCGRect: placement0],
                                         [NSValue valueWithCGRect: placement1],
                                         [NSValue valueWithCGRect: placement2],
                                         [NSValue valueWithCGRect: placement3]];
        
        for (NSValue *placementValue in potentialPlacements) {
            
            CGRect potentialPlacement = [placementValue CGRectValue];
            
            
            //if (overlapWithAnother == NO) {
                
                CGFloat potentialPlacementDistanceFromDropPoint = CGDistance(potentialPlacement.origin, layout.frame.origin);
                BOOL dropPointIsOrigin = CGPointEqualToPoint(potentialPlacement.origin, layout.frame.origin);
                
                if (((potentialPlacementDistanceFromDropPoint < distanceFromDropPoint && dropPointIsOrigin == NO) ||
                     dropPointIsOrigin ||
                     distanceFromDropPoint < 0)) {
                    
                    distanceFromDropPoint = potentialPlacementDistanceFromDropPoint;
                    nearestRect = potentialPlacement;
                    
                    
                    //validPoint = YES;
                    NSLog(@"NEAREST RECT UPDATED");
                }
                
                
                NSLog(@"Index path:                                     %@", placedLayout.indexPath);
                NSLog(@"Drop point:                                     %@", NSStringFromCGPoint(layout.frame.origin));
                NSLog(@"Potential point:                                %@", NSStringFromCGPoint(potentialPlacement.origin));
                NSLog(@"Nearest rect:                                   %@", NSStringFromCGRect(nearestRect));
                //NSLog(@"Valid point:                                    %@", validPoint ? @"YES" : @"NO");
                NSLog(@"Drop point is origin:                           %@", dropPointIsOrigin ? @"YES" : @"NO");
                NSLog(@"Distance from drop point:                       %f", distanceFromDropPoint);
                NSLog(@"Potential placement distance from drop point:   %f", potentialPlacementDistanceFromDropPoint);
                NSLog(@" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
                
            //}
            
        }
    }
    layout.frame = nearestRect;
//    MTCollectionViewLayoutLiquidAttributes *results = [layout copy];
    return [[layout retain] autorelease];
}

- (void)prepareLayout {
    NSLog(@"prepareLaout");
    [super prepareLayout];

    
    NSInteger numberOfSections = 1;
    
    NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] initWithCapacity: numberOfSections];
    
    
    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {

        NSInteger numberOfItems = [[self delegate] numberOfItemsInSection:sectionIndex ofCollectionView:[self collectionView]];
        NSMutableArray *layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];

        NSMutableArray *itemLayouts = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
            
            NSIndexPath *indexPath = [[NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex] retain];
            
            MTCollectionViewLayoutLiquidAttributes *itemAttributes = [MTCollectionViewLayoutLiquidAttributes layoutAttributesForCellWithIndexPath:indexPath];

            CGSize itemSize = [[self delegate] collectionView: [self collectionView]
                                                       layout: self
                                       sizeForItemAtIndexPath: indexPath];
            
            CGPoint dropPoint = [[self delegate] collectionView: [self collectionView]
                                                         layout: self
                                    dropPointForItemAtIndexPath: indexPath];
            CGPoint lastTouchPoint = [[self delegate] collectionView:[self collectionView] layout:self lastTouchPointForItemAtIndexPath:indexPath];
            
            NSUInteger dropIndex = [[self delegate] collectionView:[self collectionView] layout:self dropIndexForItemAtIndexPath:indexPath];
            
            
            [itemAttributes setFrame:CGRectMake(dropPoint.x, dropPoint.y, itemSize.width, itemSize.height)];
            [itemAttributes setDropIndex:dropIndex];
            [itemAttributes setDropPoint:CGPointMake(dropPoint.x, dropPoint.y)];
            [itemAttributes setLastTouchPoint:CGPointMake(lastTouchPoint.x, lastTouchPoint.y)];
            [itemAttributes setLastTouchPointValid:NO];
            
            [itemLayouts addObject:itemAttributes];
            [itemAttributes release];
            [indexPath release];
 
        }
        
        [itemLayouts sortUsingComparator:^NSComparisonResult(MTCollectionViewLayoutLiquidAttributes *layout1, MTCollectionViewLayoutLiquidAttributes *layout2) {

            return (layout1.dropIndex > layout2.dropIndex) ? NSOrderedDescending : NSOrderedAscending;
            
        }];
        
        MTCollectionViewLayoutLiquidAttributes *lastItem = [itemLayouts lastObject];
        [lastItem setLastTouchPointValid:YES];
        NSUInteger indexOfPotentiallyDroppedItem = [lastItem dropIndex];
        
        
        for (MTCollectionViewLayoutLiquidAttributes *itemAttributes in itemLayouts) {

            [itemAttributes retain];
            if (itemAttributes.indexPath.item == 1) {
                BOOL breakp = YES;
            } else if (itemAttributes.indexPath.item == 2) {
                BOOL breakp = YES;
            } else if (itemAttributes.indexPath.item == 3) {
                BOOL breakp = YES;
            }
            
            CGRect nearestRect;

            if ([layoutAttributesForSection count] == 0) {

                itemAttributes.frame = CGRectMake(CGPointZero.x, CGPointZero.y, itemAttributes.frame.size.width, itemAttributes.frame.size.height);
                
                [layoutAttributesForSection addObject:itemAttributes];

            } else {
                
                //Try every placement option to the bottom-right of existing items, while
                //  checking for overlap with every already placed item.  The shortest
                //  path to the drop path wins.
                MTCollectionViewLayoutLiquidAttributes *updatedLayout = [[self placeLayouts:layoutAttributesForSection forLayout:itemAttributes] retain];
                
                //If placing the dropped item, check to see if it overlaps anything.
                
                
                if ([updatedLayout dropIndex] == indexOfPotentiallyDroppedItem) {

                    [self repositionLayouts:layoutAttributesForSection forLayout:updatedLayout];
                    
                    /*
                    BOOL overlapWithAnother = NO;
                    NSMutableArray *layoutsToReposition = [[NSMutableArray alloc] init];
                    
                    for (MTCollectionViewLayoutLiquidAttributes *layoutForSection in layoutAttributesForSection) {
                        [layoutForSection retain];
                        
                        if (CGRectIntersectsRect([layoutForSection frame], [updatedLayout frame]) &&
                            [updatedLayout dropIndex] != [layoutForSection dropIndex]) {
                            
                            [layoutsToReposition addObject:layoutForSection];
                            overlapWithAnother = YES;
                        }
                        
                        [layoutForSection release];
                    }
                    
                    if (overlapWithAnother) {
                        for (MTCollectionViewLayoutLiquidAttributes *layoutToChange in layoutsToReposition) {
                            
                            NSSet *availablePositions = [[self availablePositionsOfRect:[layoutToChange frame] aroundRect:[updatedLayout frame]] retain];
                            NSArray *availablePositionsOrdered = [[availablePositions allObjects] retain];
                            NSUInteger indexOfNearestPosition = -1;
                            CGFloat distanceToNearest = 0.0000f;
                            NSUInteger positionCounter = 0;
                            for (NSValue *availablePositionsValue in availablePositionsOrdered) {
                                CGRect availablePosition = [availablePositionsValue CGRectValue];
                                CGFloat d = CGDistance(availablePosition.origin, updatedLayout.frame.origin);
                                if (indexOfNearestPosition == -1 || d < distanceToNearest) {
                                    distanceToNearest = d;
                                    indexOfNearestPosition = positionCounter;
                                }
                                positionCounter++;
                            }
                            
                            [layoutToChange setFrame: [[availablePositionsOrdered objectAtIndex:indexOfNearestPosition] CGRectValue]];
                            [layoutToChange setDropIndex: [[self delegate] collectionView:[self collectionView] layout:self updateDropIndexForItemAtIndexPath:[layoutToChange indexPath]]];
                            [layoutToChange setDropPoint: [layoutToChange frame].origin];
                            [[self delegate] collectionView:[self collectionView] layout:self setDropPoint:[layoutToChange frame].origin forItemAtIndexPath:[layoutToChange indexPath]];
                            [layoutToChange setLastTouchPointValid: NO];

                            [availablePositionsOrdered release];
                            [availablePositions release];
                            
                            
                            //recursive call.
                            
                        }
                     
                     
                    }

                    [layoutsToReposition release];
*/
                }
                 
                
                
                
                [layoutAttributesForSection addObject:updatedLayout];
                
                [updatedLayout release];
            }
            
            
            
            [itemAttributes release];
        }
        NSUInteger collectionViewIndexAfterSort = 0;
        
        for (MTCollectionViewLayoutLiquidAttributes *layout in layoutAttributesForSection) {

            //NSIndexPath *indexPath = [[NSIndexPath indexPathForItem:collectionViewIndexAfterSort inSection:sectionIndex] retain];
            //[layout setIndexPath: indexPath];
            //[[self delegate] collectionView:[self collectionView] layout:self
            //                   setDropPoint:layout.frame.origin forItemAtIndexPath:layout.indexPath];
            //[indexPath release];
            
            collectionViewIndexAfterSort++;
        }

        
        [itemAttributesBySection addObject:layoutAttributesForSection];
        
        [layoutAttributesForSection release];
    }

    [self setContentSize:CGSizeMake(1000.0000f, 1000.0000f)];
    [self setItemAttributesBySection:itemAttributesBySection];
    
    [itemAttributesBySection release];
}

/*
- (NSSet *)cornersOfRect:(CGRect)rect {

    //There exist four potental placement spots for each alredy placed rect
    CGFloat x1 = rect.origin.x;
    CGFloat x2 = rect.origin.x + rect.size.width;
    CGFloat y1 = rect.origin.y;
    CGFloat y2 = rect.origin.y + rect.size.height;
    
    CGRect placement0, placement1, placement2, placement3;
    
    placement0 = CGRectMake(x1, y1, rect.size.width, rect.size.height);
    placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
    placement2 = CGRectMake(x2, y2, rect.size.width, rect.size.height);
    placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);

    
    return [[[NSSet setWithObjects:
            [NSValue valueWithCGRect: placement0],
            [NSValue valueWithCGRect: placement1],
            [NSValue valueWithCGRect: placement2],
            [NSValue valueWithCGRect: placement3], nil] retain] autorelease];
}
 */

- (NSSet *)positionsOfRects:(CGRect)rect aroundRect:(CGRect)centerRect {
    
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
    
    
    return [[[NSSet setWithObjects:
              [NSValue valueWithCGRect: placement0],
              [NSValue valueWithCGRect: placement1],
              [NSValue valueWithCGRect: placement2],
              [NSValue valueWithCGRect: placement3], nil] retain] autorelease];
}

- (NSSet *)availablePositionsOfRect:(CGRect)rect aroundRect:(CGRect)centerRect {
    
    //There exist two potental placement spots around a rect to put another rect.
    CGFloat x1 = centerRect.origin.x;
    CGFloat x2 = centerRect.origin.x + centerRect.size.width;
    CGFloat y1 = centerRect.origin.y;
    CGFloat y2 = centerRect.origin.y + centerRect.size.height;
    
    CGRect placement1, placement3;
    
    placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
    placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);
    
    
    return [[[NSSet setWithObjects:
              [NSValue valueWithCGRect: placement1],
              [NSValue valueWithCGRect: placement3], nil] retain] autorelease];
}


- (void)repositionLayouts:(NSArray *)layouts forLayout:(MTCollectionViewLayoutLiquidAttributes *)layoutToReposition {
    
    BOOL overlapWithAnother = NO;
    NSMutableArray *layoutsToReposition = [[NSMutableArray alloc] init];
    
    for (MTCollectionViewLayoutLiquidAttributes *layoutForSection in layouts) {
        [layoutForSection retain];
        
        if (CGRectIntersectsRect([layoutForSection frame], [layoutToReposition frame]) &&
            [layoutToReposition dropIndex] != [layoutForSection dropIndex]) {
            
            [layoutsToReposition addObject:layoutForSection];
            overlapWithAnother = YES;
        }
        
        [layoutForSection release];
    }
    
    if (overlapWithAnother) {
        for (MTCollectionViewLayoutLiquidAttributes *layoutToChange in layoutsToReposition) {
            
            NSSet *availablePositions = [[self availablePositionsOfRect:[layoutToChange frame]
                                                             aroundRect:[layoutToReposition frame]] retain];
            NSArray *availablePositionsOrdered = [[availablePositions allObjects] retain];
            NSUInteger indexOfNearestPosition = -1;
            CGFloat distanceToNearest = 0.0000f;
            NSUInteger positionCounter = 0;
            for (NSValue *availablePositionsValue in availablePositionsOrdered) {
                CGRect availablePosition = [availablePositionsValue CGRectValue];
                CGFloat d = CGDistance(availablePosition.origin, layoutToReposition.frame.origin);
                if (indexOfNearestPosition == -1 || d < distanceToNearest) {
                    distanceToNearest = d;
                    indexOfNearestPosition = positionCounter;
                }
                positionCounter++;
            }
            
            [layoutToChange setFrame: [[availablePositionsOrdered objectAtIndex:indexOfNearestPosition] CGRectValue]];
            [layoutToChange setDropIndex: [[self delegate] collectionView:[self collectionView] layout:self updateDropIndexForItemAtIndexPath:[layoutToChange indexPath]]];
            [layoutToChange setDropPoint: [layoutToChange frame].origin];
            [[self delegate] collectionView:[self collectionView] layout:self setDropPoint:[layoutToChange frame].origin forItemAtIndexPath:[layoutToChange indexPath]];
            [layoutToChange setLastTouchPointValid: NO];
            
            [availablePositionsOrdered release];
            [availablePositions release];
            
            
            //recursive call.
            [self repositionLayouts:layouts forLayout:layoutToChange];
        }    
    }
    
    [layoutsToReposition release];
}

/*

- (UICollectionViewLayoutAttributes *)layoutOfItemDroppedAtRect:(CGRect)rect {
 
    //CGRect rect = CGRectMake(dropPoint.x, dropPoint.y, itemSize.width, itemSize.height);
 
    CGRect nearestRect;
//    NSUInteger placementIndex = item;
 
    //NSMutableArray *placedItemFrame = [[NSMutableArray alloc] initWithArray:[self placedItemFrame]];
 
 
 
    if ([layoutAttributesForSection count] == 0 || CGPointEqualToPoint(dropPoint, CGPointZero)) {
 
        nearestRect = CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
 
    } else {
 
        for (UICollectionViewLayoutAttributes *placedLayout in layoutAttributesForSection) {
 
            //CGRect placedRect = layout.frame;
            
            //There exist three potental placement spots for each alredy placed rect
            CGRect placement1, placement2, placement3;
            CGFloat x1 = placedLayout.frame.origin.x;
            CGFloat x2 = placedLayout.frame.origin.x + placedLayout.frame.size.width;
            CGFloat y1 = placedLayout.frame.origin.y;
            CGFloat y2 = placedLayout.frame.origin.y + placedLayout.frame.size.height;
            placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
            placement2 = CGRectMake(x2, y2, rect.size.width, rect.size.height);
            placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);
            
            CGFloat distanceFromDropPoint;
            BOOL validPoint;
            
            NSArray *potentialPlacements = @[[NSValue valueWithCGRect: placement1],
                                             [NSValue valueWithCGRect: placement2],
                                             [NSValue valueWithCGRect: placement3]];
            for (NSValue *placementValue in potentialPlacements) {
                
                CGRect potentialPlacement = [placementValue CGRectValue];
                
                CGFloat potentialPlacementDistanceFromDropPoint = CGDistance(potentialPlacement.origin, dropPoint);
                
                if ((validPoint && potentialPlacementDistanceFromDropPoint < distanceFromDropPoint) ||
                    validPoint == NO) {
                    
                    distanceFromDropPoint = potentialPlacementDistanceFromDropPoint;
                    nearestRect = potentialPlacement;
                    
                }
                
                validPoint = YES;
            }
        }
        
    }
    
    itemAttributes.frame = nearestRect;
}
 
 */

- (CGRect)placeObjectWithSize:(CGSize)size atDropPoint:(CGPoint)point {

    CGRect rect = CGRectMake(point.x, point.y, size.width, size.height);
    
    CGRect nearestRect;
    CGPoint dropPoint = rect.origin;
    NSUInteger placementIndex = 0;
    
    NSMutableArray *placedItemFrame = [[NSMutableArray alloc] initWithArray:[self placedItemFrame]];
    
    if ([placedItemFrame count] == 0 || CGPointEqualToPoint(dropPoint, CGPointZero)) {
        
        nearestRect = CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
        
    } else {
        
        for (NSValue *rectValue in placedItemFrame) {
            
            CGRect placedRect = [rectValue CGRectValue];
            
            //There exist three potental placement spots for each alredy placed rect
            CGRect placement1, placement2, placement3;
            placement1 = CGRectMake(placedRect.origin.x + placedRect.size.width, placedRect.origin.y, rect.size.width, rect.size.height);
            placement2 = CGRectMake(placedRect.origin.x + placedRect.size.width, placedRect.origin.y + placedRect.size.height, rect.size.width, rect.size.height);
            placement3 = CGRectMake(placedRect.origin.x, placedRect.origin.y + placedRect.size.height, rect.size.width, rect.size.height);
            
            CGFloat distanceFromDropPoint;
            BOOL validPoint;
            
            NSArray *potentialPlacements = @[[NSValue valueWithCGRect: placement1],
                                             [NSValue valueWithCGRect: placement2],
                                             [NSValue valueWithCGRect: placement3]];
            for (NSValue *placementValue in potentialPlacements) {
                
                CGRect potentialPlacement = [placementValue CGRectValue];
                
                CGFloat potentialPlacementDistanceFromDropPoint = CGDistance(potentialPlacement.origin, dropPoint);
                
                if ((validPoint && potentialPlacementDistanceFromDropPoint < distanceFromDropPoint) ||
                    validPoint == NO) {
                    
                    distanceFromDropPoint = potentialPlacementDistanceFromDropPoint;
                    nearestRect = potentialPlacement;
                    
                }
                
                validPoint = YES;
            }
        }
        
    }

    
    
    [placedItemFrame release];
    
    //If it's the first item, then it's easy.
    CGRect newRect;
    
    
    
    
    if ([[self placedItemFrame] count] == 0) {
        
        newRect = CGRectMake(CGPointZero.x, CGPointZero.y, size.width, size.height);
        [[self placedItemFrame] addObject:[NSValue valueWithCGRect:newRect]];
        
    } else {
        
        //Well, it's not the first item.
        
        //Check for new insert
        if ([[self placedItemFrame] count] == [self totalNumberOfItems] - 1 &&
            CGPointEqualToPoint(point, CGPointZero)) {
            
            CGRect initalRect = [[[self placedItemFrame] objectAtIndex:0] CGRectValue];

            //CGRect intersection = CGRectIntersection(, );
//            if (CGRectIsNull(intersection) == NO) {

//            }

        }
        
        
        //Check for new item (drop point of CGPointZero)
        
        //Create a line between CGPointZero and the drop point.  See what box it crosses
        //  that is nearest, by checking the bottom and right edges of the frame.
        
//        BOOL foundIntercept = NO;

        CGPoint touch1a = point;
        CGPoint originPoint = CGPointZero;
        
        CGLineSegment vector = CGLineSegmentMake(touch1a, originPoint);

        CGPoint newOrigin = [self blockIntercept:vector];
        
        newRect = CGRectMake(newOrigin.x, newOrigin.y, size.width, size.height);
        
        //Handles dropped rects...
        
        BOOL inGoodSpot = NO;
        while (inGoodSpot == NO) {
            BOOL againstLeftWall = [self againstLeftWall:newRect];
            BOOL againstTopWall;
            if (againstLeftWall == NO) {
                
                //Find the nearest rect to the left of the dropped rect.
                
                CGFloat distanceToWall = newRect.origin.x - CGPointZero.x;
                CGRect pathToLeftWall = CGRectMake(CGPointZero.x, newRect.origin.y, distanceToWall, newRect.size.height);
                
                CGRect closesRect = CGRectZero;
                BOOL slidePathFound;
                for (NSValue *rectValue in [self placedItemFrame]) {
                    CGRect existingRect = [rectValue CGRectValue];
                    if (CGRectIntersectsRect(pathToLeftWall, existingRect)) {
                        
                        CGFloat newD = newRect.origin.x - (existingRect.origin.x + existingRect.size.width);
                        if (newD < distanceToWall) {
                            distanceToWall = newD;
                            slidePathFound = YES;
                            closesRect = existingRect;
                        }
                        
                    }
                }

                //If there are other rects in slide path,
                //  then bump up against them.  Otherwise
                //  bump up against the wall.
 
                if (slidePathFound) {
                    CGFloat originX = closesRect.origin.x + closesRect.size.width;
                    newRect = CGRectMake(originX, newRect.origin.y, newRect.size.width, newRect.size.height);
                } else {
                    newRect = CGRectMake(CGPointZero.x, newRect.origin.y, newRect.size.width, newRect.size.height);
                }
            
            } else if ((againstTopWall = [self againstTopWall:newRect]) == NO) {

                //Find the nearest rect to the top of the dropped rect.
                CGFloat distanceToWall = newRect.origin.y - CGPointZero.y;
                CGRect pathToTopWall = CGRectMake(newRect.origin.x, CGPointZero.y, newRect.size.width, distanceToWall);

                CGRect closesRect = CGRectZero;
                BOOL slidePathFound;
                for (NSValue *rectValue in [self placedItemFrame]) {
                    CGRect existingRect = [rectValue CGRectValue];
                    if (CGRectIntersectsRect(pathToTopWall, existingRect)) {
                        
                        CGFloat newD = newRect.origin.y - (existingRect.origin.y + existingRect.size.height);
                        if (newD < distanceToWall) {
                            distanceToWall = newD;
                            slidePathFound = YES;
                            closesRect = existingRect;
                        }
                        
                    }
                }
                
                //If there are other rects in slide path,
                //  then bump up against them.  Otherwise
                //  bump up against the wall.

                if (slidePathFound) {
                    CGFloat originY = closesRect.origin.y + closesRect.size.height;
                    newRect = CGRectMake(newRect.origin.x, originY, newRect.size.width, newRect.size.height);
                } else {
                    newRect = CGRectMake(newRect.origin.x, CGPointZero.y, newRect.size.width, newRect.size.height);
                }
                
                
            } else {
                //In a good spot.
                inGoodSpot = YES;
            }
        }
        
        [[self placedItemFrame] addObject:[NSValue valueWithCGRect:newRect]];
        
    }
    return newRect;
}

- (CGRect)nearestPlacementSpotOfRect:(CGRect)rect
           givenAlreadyPlacedItems:(NSArray *)placedRects {
    
    CGRect nearestRect;
    CGPoint dropPoint = rect.origin;
    
    if ([placedRects count] == 0 || CGPointEqualToPoint(dropPoint, CGPointZero)) {

        nearestRect = CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
    
    } else {

        for (NSValue *rectValue in placedRects) {
            
            CGRect placedRect = [rectValue CGRectValue];
            
            //There exist three potental placement spots for each alredy placed rect
            CGRect placement1, placement2, placement3;
            placement1 = CGRectMake(placedRect.origin.x + placedRect.size.width, placedRect.origin.y, rect.size.width, rect.size.height);
            placement2 = CGRectMake(placedRect.origin.x + placedRect.size.width, placedRect.origin.y + placedRect.size.height, rect.size.width, rect.size.height);
            placement3 = CGRectMake(placedRect.origin.x, placedRect.origin.y + placedRect.size.height, rect.size.width, rect.size.height);
            
            CGFloat distanceFromDropPoint;
            BOOL validPoint;
            
            NSArray *potentialPlacements = @[[NSValue valueWithCGRect: placement1],
                                             [NSValue valueWithCGRect: placement2],
                                             [NSValue valueWithCGRect: placement3]];
            for (NSValue *placementValue in potentialPlacements) {
                
                CGRect potentialPlacement = [placementValue CGRectValue];
                
                CGFloat potentialPlacementDistanceFromDropPoint = CGDistance(potentialPlacement.origin, dropPoint);
                
                if ((validPoint && potentialPlacementDistanceFromDropPoint < distanceFromDropPoint) ||
                    validPoint == NO) {
                    
                    distanceFromDropPoint = potentialPlacementDistanceFromDropPoint;
                    nearestRect = potentialPlacement;
                    
                }
                
                validPoint = YES;
            }
        }

    }

    return nearestRect;
}

- (BOOL)againstLeftWall:(CGRect)rect {

    BOOL result = NO;
    
    CGPoint rectBottomLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    CGLineSegment rectLeftEdge = CGLineSegmentMake(rect.origin, rectBottomLeft);
    
    for (NSValue *rectValue in [self placedItemFrame]) {
        CGRect placedRect = [rectValue CGRectValue];

        CGPoint existingRectTopRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
        CGPoint existingRectBottomRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGLineSegment existingRectRightEdge = CGLineSegmentMake(existingRectTopRight, existingRectBottomRight);
        
        //Fast intersection comparson
        if (CGFloatCompare(rect.origin.x, placedRect.origin.x + placedRect.size.width) &&
            ((existingRectRightEdge.start.y > rectLeftEdge.start.y && rectLeftEdge.start.y > existingRectRightEdge.end.y) ||
            (existingRectRightEdge.start.y > rectLeftEdge.end.y && rectLeftEdge.end.y > existingRectRightEdge.end.y))) {

                result = YES;
                break;
        }
    }
    return result;
}

- (BOOL)againstTopWall:(CGRect)rect {
    
    BOOL result = NO;
    
    CGPoint rectTopRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    CGLineSegment rectTopEdge = CGLineSegmentMake(rect.origin, rectTopRight);
    
    for (NSValue *rectValue in [self placedItemFrame]) {
        CGRect placedRect = [rectValue CGRectValue];
        
        CGPoint existingRectBottomLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
        CGPoint existingRectBottomRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGLineSegment existingRectBottomEdge = CGLineSegmentMake(existingRectBottomLeft, existingRectBottomRight);
        
        //Fast intersection comparson
        if (CGFloatCompare(rect.origin.x, placedRect.origin.x + placedRect.size.height) &&
            ((existingRectBottomEdge.start.x > rectTopEdge.start.x && rectTopEdge.start.x > existingRectBottomEdge.end.x) ||
             (existingRectBottomEdge.start.x > rectTopEdge.end.x && rectTopEdge.end.x > existingRectBottomEdge.end.x))) {

                result = YES;
                break;
            }
    }
    return result;
}

- (CGPoint)blockIntercept:(CGLineSegment)vector {
    
    CGPoint intercept = CGPointZero;
    
    for (NSInteger objectCounter = [[self placedItemFrame] count] - 1; objectCounter >= 0; objectCounter--) {
        
        CGRect frame = [[[self placedItemFrame] objectAtIndex: objectCounter] CGRectValue];
        
        //Bottom Line of placed rectangle - Should be horizontal
        CGPoint point1a = CGPointMake(frame.origin.x, frame.origin.y + frame.size.height);
        CGPoint point1b = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height);
        
        CGLineSegment bottomLine = CGLineSegmentMake(point1a, point1b);
        
        //Right of placed rectangle - Should be vertical
        CGPoint point2a = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y);
        CGPoint point2b = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height);
        
        CGLineSegment rightLine = CGLineSegmentMake(point2a, point2b);
        
        if (CGLineSegmentIntercept(vector, bottomLine)) {
            
            CGFloat slopeVector = CGLineSegmentSlope(vector);
            CGFloat newOriginX = bottomLine.start.y / slopeVector;
            CGFloat newOriginY = bottomLine.start.y;
            
            intercept = CGPointMake(newOriginX, newOriginY);
            
        } else if (CGLineSegmentIntercept(vector, rightLine)) {
            
            CGFloat slopeVector = CGLineSegmentSlope(vector);
            CGFloat newOriginX = rightLine.start.x;
            CGFloat newOriginY = rightLine.start.x * slopeVector;
            
            intercept = CGPointMake(newOriginX, newOriginY);
            
        }
        
    }
    
    return intercept;
}

- (CGSize)collectionViewContentSize {
    NSLog(@"collectionViewContentSize");
    return [self contentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

    NSLog(@"layoutAttributesForElementsInRect %@", NSStringFromCGRect(rect));
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    NSUInteger section = 0;
    
    for (NSArray *items in [self itemAttributesBySection]) {
        
        for (MTCollectionViewLayoutLiquidAttributes *itemAttribute in items) {

            if (CGRectIntersectsRect(rect, itemAttribute.frame)) {
                [itemAttribute retain];
                [layoutAttributes addObject:itemAttribute];
                [itemAttribute release];
            }

        }
        
        /*
        UICollectionViewLayoutAttributes *decorationAttributes = [[[self decorationAttributesBySection] objectAtIndex:section] retain];
        if (CGRectIntersectsRect(rect, decorationAttributes.frame)) {
            [layoutAttributes addObject:decorationAttributes];
        }
        [decorationAttributes release];
*/
         
        section++;
    }
    /*
    for (NSInteger section = 0; section < [[self itemAttributesBySection] count]; section++) {
        
        NSArray *items = [[self itemAttributesBySection] objectAtIndex:section];
        for (NSInteger item = 0; item < items.count; item++) {

            UICollectionViewLayoutAttributes *itemAttribute = [items objectAtIndex:item];

            if (CGRectIntersectsRect(rect, itemAttribute.frame)) {
                //NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
//                [layoutAttributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
                [layoutAttributes addObject:itemAttribute];

            }
        }

        UICollectionViewLayoutAttributes *decorationAttributes = [[[self decorationAttributesBySection] objectAtIndex:section] retain];
        if (CGRectIntersectsRect(rect, decorationAttributes.frame)) {
            [layoutAttributes addObject:decorationAttributes];
        }
        [decorationAttributes release];
    }*/
    
    return [layoutAttributes autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"layoutAttributesForSupplementaryViewOfKind %@", indexPath);

    UICollectionViewLayoutAttributes *result;
    result = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];

    return result;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"layoutAttributesForItemAtIndexPath %@", indexPath);

    NSArray *rectsForSection = [[self itemAttributesBySection] objectAtIndex:[indexPath section]];
    MTCollectionViewLayoutLiquidAttributes *layoutAttributes = [rectsForSection objectAtIndex:[indexPath item]];

    return layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"layoutAttributesForDecorationViewOfKind %@", indexPath);

    MTCollectionViewLayoutLiquidAttributes *layoutAttributes = [[self decorationAttributesBySection] objectAtIndex:[indexPath section]];
    [layoutAttributes setFrame:CGRectMake(layoutAttributes.frame.origin.x, layoutAttributes.frame.origin.y, self.collectionView.contentSize.width, layoutAttributes.frame.size.height)];
    return  layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)invalidatedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"invalidatedLayoutAttributesForItemAtIndexPath %@", indexPath);

    NSArray *rectsForSection = [[self invalidatedLayoutArray] objectAtIndex:[indexPath section]];
    MTCollectionViewLayoutLiquidAttributes *layoutAttributes = [rectsForSection objectAtIndex:[indexPath item]];

    return layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"initialLayoutAttributesForAppearingItemAtIndexPath %@", indexPath);
    
    MTCollectionViewLayoutLiquidAttributes *layoutAttributes = [[[[self itemAttributesBySection] objectAtIndex:indexPath.section] objectAtIndex:indexPath.item] copy];
    return [layoutAttributes autorelease];

}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"finalLayoutAttributesForDisappearingItemAtIndexPath %@", indexPath);

    [super layoutAttributesForItemAtIndexPath:indexPath];
    MTCollectionViewLayoutLiquidAttributes *layoutAttributes = [[[self invalidatedLayoutArray] objectAtIndex:indexPath.section] objectAtIndex: indexPath.item];
    return layoutAttributes;

}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    NSLog(@"prepareForCollectionViewUpdates %@", updateItems);

    [super prepareForCollectionViewUpdates:updateItems];
    
    for (UICollectionViewUpdateItem *updatedItem in updateItems) {

        switch ([updatedItem updateAction]) {
            case UICollectionUpdateActionInsert:
                
                //Reorganize all items
                
                break;
            case UICollectionUpdateActionDelete:
                break;
            case UICollectionUpdateActionMove:
                break;
            case UICollectionUpdateActionReload:
                break;
            case UICollectionUpdateActionNone:
                break;
            default:
                break;
        }

    }
    
    /*

    // MARK: Recalculate updated attributes.
    CGSize contentSize = CGSizeZero;
    NSUInteger sectionCounter = 0, itemCounter = 0;
    CGFloat sectionHeight = CGSizeZero.height;  //[self sectionHeight];

    for (NSArray *sectionAttributes in [self invalidatedLayoutArray]) {

        CGFloat maxWidthForSection = 0.0000f, maxHeightForSection = 0.0000f;

        for (MTCollectionViewLayoutLiquidAttributes *layoutAttributes in sectionAttributes) {

            layoutAttributes.indexPath = [NSIndexPath indexPathForItem:itemCounter inSection:sectionCounter];

            if (CGSizeEqualToSize(layoutAttributes.size, CGSizeZero)) {

                layoutAttributes.size = [[self delegate] collectionView:[self collectionView]
                                                                 layout:self
                                                 sizeForItemAtIndexPath:layoutAttributes.indexPath];

            }
            
            CGFloat sectionY = CGPointZero.y + sectionHeight * layoutAttributes.indexPath.section;
            layoutAttributes.frame = CGRectMake(maxWidthForSection, sectionY, layoutAttributes.size.width, layoutAttributes.size.height);

            if (layoutAttributes.size.height > maxHeightForSection) {
                maxHeightForSection = layoutAttributes.size.height;
            }

            maxWidthForSection += layoutAttributes.size.width;

            itemCounter++;
        }
        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
        contentSize.height += maxHeightForSection;

        sectionCounter++;
    }
     */
}

- (void)finalizeCollectionViewUpdates {

    NSLog(@"finalizeCollectionViewUpdates");
    
    [super finalizeCollectionViewUpdates];

}

- (void)invalidateLayout {
    
    NSLog(@"invalidateLayout");
    
    NSMutableArray *invalidatedLayoutArray = [[self itemAttributesBySection] copy];
    [self setInvalidatedLayoutArray:invalidatedLayoutArray];
    [invalidatedLayoutArray release];

    [super invalidateLayout];

}

@end
