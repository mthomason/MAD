//
//  MADQueryBuilderContainerController.h
//  MADQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryBuilderContainerController_h
#define Reports_MTQueryBuilderContainerController_h

#import "MADViewControllerDocumentProtocol.h"
#import "MADTabBarItemProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <UIKit/UISplitViewController.h>

@class MADQueryVisualizationViewController, MADNavigationControllerQueryBuilder, MADQueryViewController, MADocument, MADNavigationControllerQueryVisualization;

@interface MADQueryBuilderSplitViewController : UISplitViewController <MADViewControllerStandardProtocol, MADViewControllerDocumentProtocol, MADTabBarImageProtocol>

@property (readwrite, nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

+ (instancetype)newQueryBuilderSplitViewController:(MADocument *)document;
- (IBAction)redrawQueryVisualization:(id)sender;

@end

#endif
