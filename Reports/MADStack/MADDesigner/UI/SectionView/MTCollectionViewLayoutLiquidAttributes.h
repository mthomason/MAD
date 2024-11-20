//
//  MTCollectionViewLayoutLiquidAttributes.h
//  Reports
//
//  Created by Michael Thomason on 5/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
