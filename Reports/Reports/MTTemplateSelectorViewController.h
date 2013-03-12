//
//  UIVIewControllerTemplateSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTemplateSelectorViewController_h
#define Reports_MTTemplateSelectorViewController_h

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTDocumentTableViewCell.h"
#import "NSFileManager+Common.h"
#import "Constants.h"

@class MTTemplateSelectorViewController;

@protocol MTTemplateSelectorDelegate <MUIViewControllerProtocol>
@optional
- (void)uIViewControllerTemplateSelectorRequestOpenOfTemplateAtUrl:(NSURL *)url;    //Copy to correct directory and open
@end

@interface MTTemplateSelectorViewController : MTViewController
    <UITableViewDataSource, UITableViewDelegate,
        MUIViewControllerProtocol>

@property (assign) IBOutlet id <MTTemplateSelectorDelegate> templateSelectorDelegate;

@property (retain, nonatomic) IBOutlet UITableView *tableViewTemplates;
@property (assign, nonatomic) IBOutlet MTDocumentTableViewCell *uITableViewCellDocument;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end

#endif
