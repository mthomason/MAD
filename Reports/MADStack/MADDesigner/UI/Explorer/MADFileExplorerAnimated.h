//
//  MADFileExplorerAnimated.h
//  MAD Designer
//
//  Created by Michael on 1/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileExplorerAnimated_h
#define Reports_MADFileExplorerAnimated_h

#import <UIKit/UIViewControllerTransitioning.h>

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
