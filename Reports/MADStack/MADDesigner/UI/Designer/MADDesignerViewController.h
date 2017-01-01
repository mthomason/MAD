//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerViewController_h
#define Reports_MTReportDesignerViewController_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerDocumentProtocol.h"
#import "MADViewControllerProtocol.h"

@protocol MADViewControllerStandardProtocol;

@interface MADDesignerViewController : UIViewController
    <MADViewControllerDocumentProtocol, MADViewControllerProtocol>

    + (instancetype)newDesignerViewController:(MADocument *)document;
    
    @property (nonatomic, weak) IBOutlet id <MADViewControllerStandardProtocol> delegate;

    @property (nonatomic, assign) BOOL hidesStatusBar;

    - (IBAction)unwindToDesigner:(UIStoryboardSegue *)action;

@end

#endif
