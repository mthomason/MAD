//
//  MADWatermarkView.m
//  MAD
//
//  Created by Michael Thomason on 10/22/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADWatermarkView.h"
#import "MTApplicationInstance.h"

@implementation MADWatermarkView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
    [self setBackgroundColor: bgColor];
}

- (void)drawRect:(CGRect)rect {
    [MTApplicationInstance drawMadWatermarkInRect:rect];
}

@end

@implementation MADWatermarkScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIColor *bgColor = [UIColor groupTableViewBackgroundColor];
    [self setBackgroundColor: bgColor];
}

- (void)drawRect:(CGRect)rect {
    [MTApplicationInstance drawMadWatermarkInRect:rect];
}

@end
