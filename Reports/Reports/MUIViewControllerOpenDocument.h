//
//  FlipsideViewController.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewControllerQueryBuilder.h"
#import "MUIViewControllerTemplateSelector.h"
#import "NSFileManager+Reports.h"

extern NSString * const SEGUE_SHOWADDDOCUMENT;
extern NSString * const SEGUE_OPENDOCUMENT;

@interface MUIViewControllerOpenDocument : UIViewController
    <UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate,
        UIGestureRecognizerDelegate,
        UIViewControllerTemplateSelectorDelegate,
        MUIViewControllerDelegate,
        MUIViewControllerDelegate>

@property (strong, nonatomic) UIPopoverController *tableViewControllerDataSourceTypes;
@property (retain, nonatomic) IBOutlet UITableView *tableViewQueries;
@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)add:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end