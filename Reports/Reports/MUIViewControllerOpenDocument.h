//
//  FlipsideViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewControllerQueryBuilder.h"
#import "MUIViewControllerTemplateSelector.h"
#import "NSFileManager+Reports.h"
#import "MTSplitViewController.h"
#import "MTCollectionViewCellDocument.h"
#import "UIView+Animations.h"

extern NSString * const SEGUE_SHOWADDDOCUMENT;
extern NSString * const SEGUE_OPENDOCUMENT;

@interface MUIViewControllerOpenDocument : UIViewController
    <UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        MTSplitViewControllerDelegate,
        UIViewControllerTemplateSelectorDelegate,
        MUIViewControllerDelegate,
        MUIViewControllerDelegate>

@property (retain, nonatomic) IBOutlet UITableView *tableViewQueries;
@property (retain, nonatomic) IBOutlet UICollectionView *collectionViewQueries;

@property (assign, nonatomic) IBOutlet UITableViewCellDocument *uITableViewCellDocument;
@property (assign, nonatomic) IBOutlet MTCollectionViewCellDocument *collectionViewCellDocument;


@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)add:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end