//
//  FlipsideViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerOpenDocument_h
#define Reports_MTViewControllerOpenDocument_h

#import <UIKit/UIKit.h>

extern NSString * const MTSegueShowAddDocument;
extern NSString * const MTSegueShowOpenDocument;

@class MTCollectionViewCellDocument;

@interface MTViewControllerOpenDocument : UICollectionViewController

@property (nonatomic, weak) IBOutlet MTCollectionViewCellDocument *collectionViewCellDocument;
@property (nonatomic, strong, readonly) UIPopoverController *aboutPopoverController;

- (void)reloadData;

- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end

#endif
