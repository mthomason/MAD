//
//  UIViewControllerObjectSelector.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIViewControllerObjectSelector;

@protocol UIViewControllerObjectSelectorDelegate
- (void)uIViewControllerObjectSelectorFinish:(UIViewControllerObjectSelector *)controller;
@end

@interface UIViewControllerObjectSelector : UIViewController

@property (assign, nonatomic) IBOutlet id <UIViewControllerObjectSelectorDelegate> delegate;

- (IBAction)done:(id)sender;

@end