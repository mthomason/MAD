//
//  MADQueryVisualizationContentView.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/10/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationContentView.h"

@implementation MADQueryVisualizationContentView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.autoresizesSubviews = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end
