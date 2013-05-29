//
//  FlipsideViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerOpenDocument_h
#define Reports_MTViewControllerOpenDocument_h

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MTQueryBuilderViewController.h"
#import "MTTemplateSelectorViewController.h"
#import "NSFileManager+Reports.h"
#import "MTQueryBuilderContainerController.h"
#import "MTCollectionViewCellDocument.h"
#import "UIView+Animations.h"
#import "MTQueryBuilderAdvancedViewController.h"
#import "MTDocumentCellProtocol.h"

extern NSString * const MTSegueShowAddDocument;
extern NSString * const MTSegueShowOpenDocument;

@interface MTViewControllerOpenDocument : UIViewController
    <UIPopoverControllerDelegate,
        UITableViewDataSource,
        UITableViewDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        MTQueryBuilderContainerDelegate,
        MTTemplateSelectorDelegate,
        MUIViewControllerProtocol,
        MTDocumentCellProtocol>

@property (retain, nonatomic) IBOutlet UITableView *tableViewQueries;
@property (retain, nonatomic) IBOutlet UICollectionView *collectionViewQueries;

@property (assign, nonatomic) IBOutlet MTDocumentTableViewCell *uITableViewCellDocument;
@property (assign, nonatomic) IBOutlet MTCollectionViewCellDocument *collectionViewCellDocument;


@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)add:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end

#endif
