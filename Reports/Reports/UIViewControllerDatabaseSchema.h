//
//  UIViewControllerDatabaseSchema.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIViewControllerDatabaseSchema;

@protocol UIViewControllerDatabaseSchemaDelegate
- (void)viewControllerDatabaseSchemaDidFinish:(UIViewControllerDatabaseSchema *)controller;
@end

@interface UIViewControllerDatabaseSchema : UIViewController

@property (assign, nonatomic) IBOutlet id <UIViewControllerDatabaseSchemaDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollViewMain;

- (IBAction)done:(id)sender;

@end