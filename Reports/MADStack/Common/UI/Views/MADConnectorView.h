//
//  MADConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTConnectorView_h
#define Reports_MTConnectorView_h

#import "MADManagedObjectViewProtocol.h"
#import <UIKit/UIView.h>

@interface MADConnectorView : UIView <MADManagedObjectViewProtocol>

@property (nonatomic, assign) BOOL topLeftToBottomRight;
@property (nonatomic, assign) BOOL leftViewIsInital;

@end

#endif
