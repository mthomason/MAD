//
//  MTCollectionViewLayoutLiquidAttributes.h
//  Reports
//
//  Created by Michael Thomason on 5/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTCollectionViewLayoutLiquidAttributes : UICollectionViewLayoutAttributes

@property (nonatomic) CGPoint dropPoint;
@property (nonatomic) NSUInteger dropIndex;
@property (nonatomic) BOOL lastTouchPointValid;
@property (nonatomic) CGPoint lastTouchPoint;
@property (nonatomic, retain) NSString *description;

@end
