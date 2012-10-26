//
//  UIVIewControllerTemplateSelector.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCellDocument.h"
#import "UITableViewControllerDataSourceTypes.h"

@class UIViewControllerTemplateSelector;

@protocol UIViewControllerTemplateSelectorDelegate
@optional
- (void)uIViewControllerTemplateSelectorDidCancel:(UIViewControllerTemplateSelector *)controller;
- (void)uIViewControllerTemplateSelectorDidFinish:(UIViewControllerTemplateSelector *)controller;
- (void)uIViewControllerTemplateSelectorRequestOpenOfTemplateAtUrl:(NSURL *)url;    //Copy to correct directory and open
- (void)uIViewControllerTemplateSelectorRequestOpenOfFileAtUrl:(NSURL *)url;        //Just open it
@end

@interface UIViewControllerTemplateSelector : UIViewController
    <UITableViewDataSource, UITableViewDelegate,
        UITableViewControllerDataSourceTypesDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerTemplateSelectorDelegate> delegate;

@property (retain, nonatomic) IBOutlet UITableView *tableViewTemplates;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end