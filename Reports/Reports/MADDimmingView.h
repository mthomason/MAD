//
//  MADDimmingView.h
//  MAD
//
//  Created by Michael Thomason on 11/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADDimmingView : UIView

@property (nonatomic, weak) UIView *container;
@property (nonatomic, weak) UIView *passthroughContainer;
@property (nonatomic, strong) NSSet *passthoughContainers;
@property (nonatomic, strong) NSSet *passthoughViews;

@end
