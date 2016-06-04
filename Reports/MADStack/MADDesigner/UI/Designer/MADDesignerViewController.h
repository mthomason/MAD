//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerViewController_h
#define Reports_MTReportDesignerViewController_h

#import "MADViewController.h"
#import "MADocumentProtocol.h"
#import "MADViewControllerProtocol.h"

@protocol MTViewControllerProtocol;

@interface MADDesignerViewController : MADViewController
    <MADViewControllerDocumentProtocol, MADViewControllerProtocol>

    + (instancetype)newDesignerViewController;
    
    @property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

    @property (nonatomic, assign) BOOL hidesStatusBar;

    - (IBAction)unwindToDesigner:(UIStoryboardSegue *)action;

@end

#endif
