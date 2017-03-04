//
//  MADDimmingView.h
//  MAD
//
//  Created by Michael Thomason on 11/4/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDimmingView_h
#define Reports_MADDimmingView_h

#import <UIKit/UIView.h>

@interface MADDimmingView : UIView

    @property (nonatomic, weak) UIView *container;
    @property (nonatomic, weak) UIView *passthroughContainer;
    @property (nonatomic, strong) NSSet *passthroughContainers;
    @property (nonatomic, strong) NSSet *passthroughViews;

@end

#endif
