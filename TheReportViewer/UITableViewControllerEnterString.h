//
//  UITableViewControllerEnterString.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewControllerEnterString;

@protocol UITableViewControllerEnterStringDelegate
- (void)enterStringDidFinishWithString:(NSString *)userInput;
@end

@interface UITableViewControllerEnterString : UITableViewController

@property (assign, nonatomic) IBOutlet id <UITableViewControllerEnterStringDelegate> enterStringDelegate;
@property (retain, nonatomic) IBOutlet UITextField *textField;

- (IBAction)done:(id)sender;

@end