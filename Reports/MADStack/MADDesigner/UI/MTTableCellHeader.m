//
//  MTTableCellHeader.m
//  MAD
//
//  Created by Michael Thomason on 3/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableCellHeader.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UILabel.h>
#import <QuartzCore/CALayer.h>

@interface MTTableCellHeader ()

@property (nonatomic, strong, readwrite) UILabel *label;

@end

@implementation MTTableCellHeader

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    UILabel *lbl = [[UILabel alloc] initWithFrame:self.bounds];
    UIColor *bgcolor = [MADColorEverydayApps newColorBlue];
    UIColor *textColor = [MADColorEverydayApps newColorWhite];
    lbl.backgroundColor = bgcolor;
    lbl.textColor = textColor;
    lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                           UIViewAutoresizingFlexibleWidth |
                           UIViewAutoresizingFlexibleTopMargin |
                           UIViewAutoresizingFlexibleBottomMargin |
                           UIViewAutoresizingFlexibleRightMargin |
                           UIViewAutoresizingFlexibleLeftMargin;

    [self addSubview:lbl];
    self.label = lbl;
    self.layer.borderWidth = 1.0000f;
    self.layer.borderColor = bgcolor.CGColor;
}

@end
