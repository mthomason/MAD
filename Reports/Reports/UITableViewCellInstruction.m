//
//  UITableViewCellInstruction.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellInstruction.h"
#import "Constants.h"

@implementation UITableViewCellInstruction

@synthesize labelGroupType = _labelGroupType, labelGroupTypeDetail = _labelGroupTypeDetail;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        [self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        
    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        
    }
    return self;
    
}

+ (CGFloat)defaultHeight {
    return MNSTableViewCellHeightDefault;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end