//
//  labelInformationViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LabelInformationViewController;

@protocol LabelInformationViewControllerDelegate
- (void)labelInformationViewControllerDidFinish:(LabelInformationViewController *)controller;
@end

@interface LabelInformationViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <LabelInformationViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end