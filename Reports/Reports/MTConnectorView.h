//
//  MTConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+EverydayApps.h"

@interface MTConnectorView : UIView

@property (nonatomic, retain) UIView *anchorViewLeft;
@property (nonatomic, retain) UIView *anchorViewRight;
@property (nonatomic, retain) NSNumber *topLeftToBottomRight;

- (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint;

@end
