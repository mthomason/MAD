//
//  UITableViewCellTableName.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewCellQueryTableName.h"
#import "Constants.h"

@implementation MADTableViewCellQueryTableName

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.textLabel.numberOfLines = 0;
    }
    return self;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.textLabel.numberOfLines = 0;
    }
    return self;
}

+ (CGFloat)defaultHeight {
    return 44.0000f;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
