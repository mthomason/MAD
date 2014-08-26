//
//  MADBlurView.m
//  MAD
//
//  Created by Michael Thomason on 8/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADBlurView.h"
#import "UIDevice+Hack.h"

@interface MADBlurView ()

@property (nonatomic, strong) UIVisualEffectView *visualEffectsView;

@end

@implementation MADBlurView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    //self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    //self.translatesAutoresizingMaskIntoConstraints = YES;

//    if ([UIDevice isModernOS]) {
//        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
//        UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
        //visualEffectsView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        //visualEffectsView.translatesAutoresizingMaskIntoConstraints = YES;
//        [self addSubview:visualEffectsView];
//        self.visualEffectsView = visualEffectsView;
//    }
}

- (void)setFrame:(CGRect)frame {
    self.visualEffectsView.frame = frame;
    [super setFrame:frame];
}

- (void)setBounds:(CGRect)bounds {
    self.visualEffectsView.bounds = bounds;
    super.bounds = bounds;
    //[super setBounds:bounds];
}

- (void)addSubview:(UIView *)view {
    if ([UIDevice isModernOS]) {
        [self.visualEffectsView.contentView addSubview:view];
    } else {
        [super addSubview:view];
    }
}

- (void)layoutIfNeeded {
    [self.visualEffectsView.contentView layoutIfNeeded];
    [super layoutIfNeeded];
}

@end
