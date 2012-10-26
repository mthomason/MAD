//
//  UIViewControllerDatabaseSources.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIViewControllerDatabaseSources;

@protocol UIViewControllerDatabaseSourcesDelegate
- (void)viewControllerDatabaseSourcesDidFinish:(UIViewControllerDatabaseSources *)controller;
@end

@interface UIViewControllerDatabaseSources : UIViewController

@property (assign, nonatomic) IBOutlet id <UIViewControllerDatabaseSourcesDelegate> delegate;

- (IBAction)done:(id)sender;

@end
