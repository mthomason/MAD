//
//  UINavigationControllerModelControllers.h
//  Reports
//
//  Created by Michael Thomason on 2/10/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryNavigationController_h
#define Reports_MADQueryNavigationController_h

#import <UIKit/UINavigationController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADNavigationControllerIdentity.h"

@interface MADNavigationControllerQueryVisualization : UINavigationController <MADNavigationControllerIdentify, MADViewControllerDocumentProtocol>

@end

#endif
