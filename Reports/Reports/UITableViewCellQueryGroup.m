//
//  UITableViewCellQueryGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellQueryGroup.h"

@interface UITableViewCellQueryGroup ()

@property (nonatomic, weak) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;

@end

@implementation UITableViewCellQueryGroup

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    
    }
    return self;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

    }
    return self;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

+ (CGFloat)defaultHeight {
    return 88.0000f;
}

@end