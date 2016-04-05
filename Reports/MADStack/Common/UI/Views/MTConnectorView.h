//
//  MTConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTConnectorView_h
#define Reports_MTConnectorView_h

#import <UIKit/UIKit.h>
#import "MADManagedObjectView.h"

@interface MTConnectorView : MADManagedObjectView

    @property (nonatomic, strong) UIView *anchorViewLeft;
    @property (nonatomic, strong) UIView *anchorViewRight;
    @property (nonatomic, strong) NSNumber *topLeftToBottomRight;
    @property (nonatomic, strong) NSString *linkDescription;

    @property (nonatomic, assign) BOOL leftViewIsInital;

    - (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint;

@end

#endif
