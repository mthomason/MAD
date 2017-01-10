//
//  MTCollectionViewLayoutLiquidAttributes.h
//  Reports
//
//  Created by Michael Thomason on 5/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCollectionViewLayoutLiquidAttributes_h
#define Reports_MTCollectionViewLayoutLiquidAttributes_h

#import <UIKit/UICollectionViewLayout.h>

@interface MTCollectionViewLayoutLiquidAttributes : UICollectionViewLayoutAttributes
    <NSCopying>

    @property (nonatomic, assign) CGPoint dropPoint;
    @property (nonatomic, assign) NSUInteger dropIndex;
    @property (nonatomic, assign) BOOL lastTouchPointValid;
    @property (nonatomic, assign) CGPoint lastTouchPoint;
    @property (nonatomic, copy) NSString *layoutDescription;

@end

#endif
