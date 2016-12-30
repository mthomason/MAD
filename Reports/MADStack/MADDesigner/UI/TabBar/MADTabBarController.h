//
//  MADTabBarController.h
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTabBarController_h
#define Reports_MADTabBarController_h

#import <UIKit/UITabBarController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MUIViewControllerDelegate.h"

extern const int8_t MADIndexQuery;
extern const int8_t MADIndexDesigner;
extern const int8_t MADIndexViewer;

@class MADocument;
@class MADQueryBuilderSplitViewController;
@class MADDesignerViewController;
@class MADViewerController;

@interface MADTabBarController : UITabBarController
    <MADViewControllerDocumentProtocol, MADViewControllerStandardProtocol>

    + (nullable instancetype)newTabBarController:(nullable MADocument __weak *)document
                                          prompt:(nullable NSString *)prompt;

    @property (nullable, nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

    @property (nullable, readonly) MADQueryBuilderSplitViewController * querySplitViewController;
    @property (nullable, readonly) MADDesignerViewController * designerViewController;
    @property (nullable, readonly) MADViewerController * viewerViewController;

    - (void)enableTabBarItems;
    - (void)disableTabBarItems;

@end

#endif
