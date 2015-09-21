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
#import <MADExplorer/MADFileExplorerViewController.h>
#import <MAD/MADConstants.h>
#import <MAD/MADocument.h>
#import <MADFoundation/NSURL+Document.h>

@protocol MADOpenFileViewControllerDelegate <NSObject>

- (void)didOpenDocument:(MADocument *)document;

@end

@interface MADOpenFileViewController : MADFileExplorerViewController

@property (nonatomic, weak) id <MADOpenFileViewControllerDelegate> openFileDelegate;
@property (readonly) MADocument *openDocument;

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated;


- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

- (void)closeDocument:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion;
- (void)getUserCloudPrefs;
- (void)reenable;

@end

#endif
