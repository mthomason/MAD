//
//  MADTabBarNavigationController.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTabBarNavigationController_h
#define Reports_MADTabBarNavigationController_h

#import <UIKit/UINavigationController.h>
#import "MADViewControllerDocumentProtocol.h"

@interface MADTabBarNavigationController : UINavigationController
    <MADViewControllerDocumentProtocol>

@end

#endif
