//
//  MADTabBarController.h
//  MAD
//
//  Created by Michael Thomason on 10/26/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTabBarController_h
#define Reports_MADTabBarController_h

#import <UIKit/UITabBarController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADViewControllerStandardProtocol.h"

extern const int8_t MADIndexQuery;
extern const int8_t MADIndexDesigner;
extern const int8_t MADIndexViewer;

@class MADocument, MADQueryBuilderSplitViewController, MADDesignerViewController,
       MADViewerController;

@interface MADTabBarController : UITabBarController
    <MADViewControllerDocumentProtocol, MADViewControllerStandardProtocol>

    + (instancetype)newTabBarController:(MADocument *)document
                                 prompt:(NSString *)prompt;

    @property (nonatomic, weak) id <MADViewControllerStandardProtocol> viewControllerDelegate;

    @property (nonatomic, strong, readonly) MADQueryBuilderSplitViewController *querySplitViewController;
    @property (nonatomic, strong, readonly) MADDesignerViewController *designerViewController;
    @property (nonatomic, strong, readonly) MADViewerController *viewerViewController;

    - (void)enableTabBarItems;
    - (void)disableTabBarItems;

@end

#endif
