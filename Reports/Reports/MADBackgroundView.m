//
//  MADBackgroundView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADBackgroundView.h"

@implementation MADBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *bgColor = [[UIColor edaBlackFiftyPercent] colorWithAlphaComponent:0.33333333f];
        self.backgroundColor = bgColor;
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 5.0000f;
    }
    return self;
}

@end
