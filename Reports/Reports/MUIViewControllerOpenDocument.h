//
//  FlipsideViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderViewController.h"
#import "MTTemplateSelectorViewController.h"
#import "NSFileManager+Reports.h"
#import "MTQueryBuilderContainerController.h"
#import "MTCollectionViewCellDocument.h"
#import "UIView+Animations.h"
#import "MTTitleView.h"

extern NSString * const MTSegueShowAddDocument;
extern NSString * const MTSegueShowOpenDocument;

@interface MUIViewControllerOpenDocument : UIViewController
    <UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        MTQueryBuilderContainerDelegate,
        MTTemplateSelectorDelegate,
        MUIViewControllerProtocol,
        MUIViewControllerProtocol>

@property (retain, nonatomic) IBOutlet UITableView *tableViewQueries;
@property (retain, nonatomic) IBOutlet UICollectionView *collectionViewQueries;

@property (assign, nonatomic) IBOutlet MTDocumentTableViewCell *uITableViewCellDocument;
@property (assign, nonatomic) IBOutlet MTCollectionViewCellDocument *collectionViewCellDocument;


@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)add:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end