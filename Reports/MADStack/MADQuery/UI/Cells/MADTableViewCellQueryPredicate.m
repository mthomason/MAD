//
//  UITableViewCellPredicate.m
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADTableViewCellQueryPredicate.h"
#import <UIKit/UILabel.h>

@implementation MADTableViewCellQueryPredicate

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
