//
//  MTConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTConnectorView_h
#define Reports_MTConnectorView_h

#import <UIKit/UIView.h>
#import "MADManagedObjectViewProtocol.h"

@interface MADConnectorView : UIView
    <MADManagedObjectViewProtocol>

    @property (nonatomic, assign) BOOL topLeftToBottomRight;
    @property (nonatomic, assign) BOOL leftViewIsInital;

@end

#endif
