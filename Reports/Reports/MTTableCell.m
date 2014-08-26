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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    UILabel *lbl = [[UILabel alloc] initWithFrame:self.contentView.frame];
    lbl.backgroundColor = [UIColor whiteColor];
    
    [self.contentView addSubview:lbl];
    lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                           UIViewAutoresizingFlexibleWidth |
                           UIViewAutoresizingFlexibleTopMargin |
                           UIViewAutoresizingFlexibleBottomMargin |
                           UIViewAutoresizingFlexibleRightMargin |
                           UIViewAutoresizingFlexibleLeftMargin;
    self.label = lbl;
    self.contentView.layer.borderWidth = 1.0000f;
    self.contentView.layer.borderColor = [UIColor darkGrayColor].CGColor;
}

@end
