//
//  MTCollectionViewLayoutLiquidAttributes.m
//  Reports
//
//  Created by Michael Thomason on 5/7/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewLayoutLiquidAttributes.h"

@implementation MTCollectionViewLayoutLiquidAttributes

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    MTCollectionViewLayoutLiquidAttributes *copy = [super copyWithZone:zone];
    copy.dropPoint = self.dropPoint;
    copy.dropIndex = self.dropIndex;
    copy.lastTouchPointValid = self.lastTouchPointValid;
    copy.lastTouchPoint = self.lastTouchPoint;
    copy.layoutDescription = self.layoutDescription.copy;
    copy.frame = self.frame;
    return copy;
}

/*
 @property (nonatomic, assign) CGPoint dropPoint;
 @property (nonatomic, assign) NSUInteger dropIndex;
 @property (nonatomic, assign) BOOL lastTouchPointValid;
 @property (nonatomic, assign) CGPoint lastTouchPoint;
 @property (nonatomic, copy) NSString *layoutDescription;
 */

@end
