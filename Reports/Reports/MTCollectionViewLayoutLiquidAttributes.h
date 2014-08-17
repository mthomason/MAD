//
//  MTCollectionViewLayoutLiquidAttributes.h
//  Reports
//
//  Created by Michael Thomason on 5/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTCollectionViewLayoutLiquidAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, assign) CGPoint dropPoint;
@property (nonatomic, assign) NSUInteger dropIndex;
@property (nonatomic, assign) BOOL lastTouchPointValid;
@property (nonatomic, assign) CGPoint lastTouchPoint;
@property (nonatomic, strong) NSString *layoutDescription;

@end
