//
//  MADFileExplorerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileExplorerViewController_h
#define Reports_MADFileExplorerViewController_h

#import <UIKit/UICollectionViewController.h>
#import <UIKit/UIViewControllerTransitioning.h>
#import <UIKit/UINavigationController.h>

@interface MADFileExplorerViewController : UICollectionViewController

+ (instancetype)newFileExplorerViewController;

@end

@interface MADFileExplorerAnimated : NSObject
    <UIViewControllerAnimatedTransitioning>

    + (instancetype)newFileExplorerAnimatedShowToolbar:(BOOL)showToolbar pushing:(BOOL)pushing;

@end

@interface MADFileExplorerAnimatedCrossFadePush : MADFileExplorerAnimated

    - (instancetype)initToolbar:(BOOL)showToolbar;

@end

@interface MADFileExplorerAnimatedCrossFadePop : MADFileExplorerAnimated

    - (instancetype)initToolbar:(BOOL)showToolbar;

@end

#endif
