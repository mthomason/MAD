//
//  MainViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "ReportDesignerViewController.h"

@interface MainViewController : UIViewController <ReportDesignerViewControllerDelegate, FlipsideViewControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (strong, nonatomic) UIPopoverController *reportDesignerPopoverController;

@end
