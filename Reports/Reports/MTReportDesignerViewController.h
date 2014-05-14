//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerViewController_h
#define Reports_MTReportDesignerViewController_h

typedef void(^MTBlockCompletionSimple)(BOOL finished);
typedef void(^MTBlockCompletionNoReturn)(void);

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTReportDesignerViewController : UIViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

- (IBAction)doneReports:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;

@end

#endif
