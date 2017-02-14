//
//  MADExplorerAnimated.h
//  MAD Designer
//
//  Created by Michael on 1/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADExplorerAnimated_h
#define Reports_MADExplorerAnimated_h

#import <UIKit/UIViewControllerTransitioning.h>

@interface MADExplorerAnimated : NSObject
    <UIViewControllerAnimatedTransitioning>

    + (instancetype)newFileExplorerAnimatedShowToolbar:(BOOL)showToolbar pushing:(BOOL)pushing;

@end

@interface MADExplorerAnimatedCrossFadePush : MADExplorerAnimated

    - (instancetype)initToolbar:(BOOL)showToolbar;

@end

@interface MADExplorerAnimatedCrossFadePop : MADExplorerAnimated

    - (instancetype)initToolbar:(BOOL)showToolbar;

@end

#endif
