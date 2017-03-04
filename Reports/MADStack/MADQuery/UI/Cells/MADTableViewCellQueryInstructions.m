//
//  UITableViewCellInstruction.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewCellQueryInstructions.h"

const CGFloat MNSTableViewCellHeightDefault = 44.0000f;

@implementation MADTableViewCellQueryInstructions

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    if (self = [super initWithCoder:aDecoder]) {
        
        [self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        
    }
    return self;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {

    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self setBackgroundView: nil];
        [self setSelectedBackgroundView: nil];
        
    }
    return self;
    
}

+ (CGFloat)defaultHeight { return MNSTableViewCellHeightDefault; }

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
