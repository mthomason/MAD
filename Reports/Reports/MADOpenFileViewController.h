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

/*typedef NS_ENUM(NSUInteger, MTReportState) {
    MTReportStateOpen = 0,
    MTReportStateClosed
};*/

@class MADocument, MADFileManager, MADFilesController;

@interface MADOpenFileViewController : UICollectionViewController

@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readonly) BOOL rightBarButtonItemActivityIndicatorVisible;

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated;


- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

- (void)closeReport:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion;
- (void)getUserCloudPrefs;

@end

#endif
