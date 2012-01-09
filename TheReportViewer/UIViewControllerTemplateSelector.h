//
//  UIVIewControllerTemplateSelector.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCellDocument.h"

@class UIViewControllerTemplateSelector;

@protocol UIViewControllerTemplateSelectorDelegate
- (void)uIViewControllerTemplateSelectorRequestOpenOfTemplateAtUrl:(NSURL *)url;    //Copy to correct directory and open
- (void)uIViewControllerTemplateSelectorRequestOpenOfFileAtUrl:(NSURL *)url;        //Just open it
- (void)uIViewControllerTemplateSelectorDidFinish:(UIViewControllerTemplateSelector *)controller;
@end

@interface UIViewControllerTemplateSelector : UIViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerTemplateSelectorDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableView *tableViewTemplates;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;

- (IBAction)done:(id)sender;

@end