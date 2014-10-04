//
//  MADOpenFileViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADOpenFileViewController_h
#define Reports_MADOpenFileViewController_h

#import <UIKit/UIKit.h>

@class MTCollectionViewCellDocument;

@interface MADOpenFileViewController : UICollectionViewController

@property (nonatomic, weak) IBOutlet MTCollectionViewCellDocument *collectionViewCellDocument;
@property (nonatomic, strong, readonly) UIPopoverController *aboutPopoverController;
@property (nonatomic, assign, getter = isSavingActivityIndicatorVisible, readonly) BOOL savingActivityIndicatorVisible;
@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readonly) BOOL rightBarButtonItemActivityIndicatorVisible;

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible animated:(BOOL)animated;
- (void)reloadData;

- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;
- (void)openFileWithUrl:(NSURL *)url;

@end

#endif
