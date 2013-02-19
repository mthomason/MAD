//
//  UIVIewControllerTemplateSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "UITableViewCellDocument.h"
#import "NSFileManager+Common.h"
#import "Constants.h"

@class MUIViewControllerTemplateSelector;

@protocol UIViewControllerTemplateSelectorDelegate <MUIViewControllerDelegate>
@optional
- (void)uIViewControllerTemplateSelectorRequestOpenOfTemplateAtUrl:(NSURL *)url;    //Copy to correct directory and open
@end

@interface MUIViewControllerTemplateSelector : MTViewController
    <UITableViewDataSource, UITableViewDelegate,
        MUIViewControllerDelegate>

@property (assign) IBOutlet id <UIViewControllerTemplateSelectorDelegate> templateSelectorDelegate;

@property (retain, nonatomic) IBOutlet UITableView *tableViewTemplates;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end