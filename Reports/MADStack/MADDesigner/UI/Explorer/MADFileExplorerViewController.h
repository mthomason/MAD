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

@interface MADFileExplorerAnimatedCrossFadePush : NSObject
    <UIViewControllerAnimatedTransitioning>

@end

@interface MADFileExplorerAnimatedCrossFadePop : NSObject
    <UIViewControllerAnimatedTransitioning>

@end

#endif
