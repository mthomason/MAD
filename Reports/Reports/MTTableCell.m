//
//  MTTableCell.m
//  MAD
//
//  Created by Michael Thomason on 3/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableCell.h"

@interface MTTableCell ()

@property (nonatomic, strong, readwrite) UILabel *label;

@end

@implementation MTTableCell

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

- (id)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    UILabel *lbl = [[UILabel alloc] initWithFrame:[[self contentView] frame]];
    [lbl setBackgroundColor:[UIColor whiteColor]];
    [[self contentView] addSubview:lbl];
    [lbl setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
    [self setLabel:lbl];
    [[[self contentView] layer] setBorderWidth:1.0000f];
    [[[self contentView] layer] setBorderColor:[UIColor darkGrayColor].CGColor];
}

@end
