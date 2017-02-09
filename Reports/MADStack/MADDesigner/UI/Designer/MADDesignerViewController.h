//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDesignerViewController_h
#define MAD_MADDesignerViewController_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADViewControllerProtocol.h"
#import "MADTabBarItemProtocol.h"

@protocol MADViewControllerStandardProtocol;

@interface MADDesignerViewController : UIViewController
    <MADViewControllerDocumentProtocol,
        MADViewControllerProtocol,
        MADTabBarImageProtocol>

    + (instancetype)newDesignerViewController:(MADocument *)document;
    
    @property (nonatomic, weak) IBOutlet id <MADViewControllerStandardProtocol> delegate;

    @property (nonatomic, assign) BOOL hidesStatusBar;

    - (IBAction)unwindToDesigner:(UIStoryboardSegue *)action;

@end

#endif
