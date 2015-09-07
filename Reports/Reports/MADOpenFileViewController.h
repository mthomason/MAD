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
#import "MADViewController.h"

@class MADFilesController;

@interface MADOpenFileViewController : MADCollectionViewController

@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readonly) BOOL rightBarButtonItemActivityIndicatorVisible;
@property (nonatomic, weak) MADFilesController *filesController;

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated;


- (IBAction)done:(id)sender;
- (IBAction)edit:(id)sender;

@end

#endif
