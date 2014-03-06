//
//  MADWatermarkView.m
//  MAD
//
//  Created by Michael Thomason on 10/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MADWatermarkView.h"
#import "MTApplicationInstance.h"

@implementation MADWatermarkView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
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

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
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
