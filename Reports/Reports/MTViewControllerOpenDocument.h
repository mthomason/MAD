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
#import "UIManagedDocument+FileOperations.h"
#import "MTViewControllerAsyncProtocol.h"

extern NSString * const MTSegueShowAddDocument;
extern NSString * const MTSegueShowOpenDocument;

@interface MTViewControllerOpenDocument : UICollectionViewController
    <UIPopoverControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        MTTemplateSelectorDelegate,
        MTViewControllerProtocol,
        MTDocumentCellProtocol,
        MTViewControllerAsyncProtocol>

@property (nonatomic, assign) IBOutlet MTCollectionViewCellDocument *collectionViewCellDocument;

- (IBAction)add:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

- (void)updateFileList;

@end

#endif
