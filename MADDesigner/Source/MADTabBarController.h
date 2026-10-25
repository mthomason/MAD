//
//  MADTabBarController.h
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADTabBarController_h
#define Reports_MADTabBarController_h

#import "MADViewControllerDocumentProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <UIKit/UITabBarController.h>

@class MADocument, MADQueryBuilderSplitViewController, MADDesignerViewController, MADViewerController;

@interface MADTabBarController : UITabBarController <MADViewControllerDocumentProtocol, MADViewControllerStandardProtocol>

+ (instancetype)newTabBarController:(MADocument *)document
							 prompt:(NSString *)prompt;

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

- (void)enableTabBarItems;
- (void)disableTabBarItems;

@end

#endif
