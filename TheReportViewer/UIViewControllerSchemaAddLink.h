//
//  UIViewControllerSchemaAddLink.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIViewControllerSchemaAddLink;

@protocol UIViewControllerSchemaAddLinkDelegate
- (void)viewControllerSchemaAddLinkDidFinish:(UIViewControllerSchemaAddLink *)controller;
@end

@interface UIViewControllerSchemaAddLink : UITableViewController

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkDelegate> delegate;

- (IBAction)done:(id)sender;

@end