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
#import <MessageUI/MessageUI.h>
#import <MADFileManager/MADFileManager.h>
#import "MADFileExplorerViewController.h"

@class MADocument, MADFileManager, MADFilesController;

@interface MADOpenFileViewController : MADFileExplorerViewController

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated;


- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

- (void)closeReport:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion;
- (void)getUserCloudPrefs;

@end

#endif
