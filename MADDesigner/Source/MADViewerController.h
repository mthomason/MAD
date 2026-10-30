//
//  MADViewerController.h
//  Reports
//
//  Created by Michael Thomason on 7/20/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADViewerController_h
#define Reports_MADViewerController_h

#import "MADViewControllerDocumentProtocol.h"
#import "MADTabBarItemProtocol.h"
#import "MADOperationRefreshReload.h"
#import "MADOperationRefreshReloadProtocol.h"

#import <MAD/MADActivityProtocol.h>
#import <MAD/MADPaperType.h>

#import <UIKit/UIPageViewController.h>

@protocol MADViewControllerStandardProtocol;

@interface MADViewerController : UIPageViewController <MADViewControllerDocumentProtocol, MADTabBarImageProtocol, MADOperationRefreshReloadProtocol>

@property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;
@property (nonatomic, assign) MTPaperType selectedPaperType;
@property (nonatomic, assign, readonly) MTPaperType renderedPaperType;

+ (instancetype)newViewerController:(MADocument *)document;

- (void)selectPaperType:(MTPaperType)paperType;
- (IBAction)refresh:(id)sender;
- (IBAction)zoomToActualSize:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)zoomToFullScreen:(id)sender;

@end

#endif
