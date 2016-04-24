//
//  MTConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTConnectorView_h
#define Reports_MTConnectorView_h

#import "MADManagedObjectView.h"

@interface MADConnectorView : MADManagedObjectView

    @property (nonatomic, assign) bool topLeftToBottomRight;
    @property (nonatomic, assign) bool leftViewIsInital;

    - (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint;

@end

#endif
