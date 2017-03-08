//
//  UITableViewCellQueryLink.m
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewCellQueryLink.h"
#import <UIKit/UILabel.h>
#import "Constants.h"

@implementation MADTableViewCellQueryLink

+ (CGFloat)defaultHeight {
    return MNSTableViewCellQueryLinkHeightDefault;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textLabel.numberOfLines = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.textLabel.numberOfLines = 0;
    }
    return self;
}

@end
