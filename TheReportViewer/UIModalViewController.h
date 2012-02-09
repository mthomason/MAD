//
//  UIModalViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/19/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIModalViewController;

@protocol ModalViewControllerDelegate
- (void)modalViewControllerDidFinish:(id)controller;
@end

@interface UIModalViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <ModalViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end