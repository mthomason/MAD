//
//  MADExplorerAnimatedTransitioning.h
//  MAD Designer
//
//  Created by Michael on 8/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADExplorerAnimatedTransitioning_h
#define MAD_Designer_MADExplorerAnimatedTransitioning_h

#import <Foundation/NSObject.h>
#import <UIKit/UIViewControllerTransitioning.h>

@interface MADExplorerAnimatedTransitioningDelegate : NSObject
    <UIViewControllerTransitioningDelegate>

@end

@interface MADExplorerAnimatedTransitioning : NSObject
    <UIViewControllerAnimatedTransitioning>

@end

#endif
