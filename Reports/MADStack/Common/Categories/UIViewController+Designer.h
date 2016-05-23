//
//  UIViewController+Designer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIViewController_Designer_h
#define Reports_UIViewController_Designer_h

#import <UIKit/UIViewController.h>

@class MADQueryVisualizationSchemaViewController;

@interface UIViewController (Designer)

    + (instancetype)layoutSettingsViewController;
    + (instancetype)fileManager;
    + (instancetype)queryViewController;
    + (instancetype)queryContainerController;
    + (instancetype)viewerNavigationController;
    + (instancetype)designerViewController;
    + (instancetype)designerNavigationController;
    + (instancetype)viewerViewController;
    + (instancetype)initalViewController;

@end

#endif
