//
//  UITableViewCellQueryGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewCellQueryGroup.h"
#import <UIKit/UILabel.h>

@interface MADTableViewCellQueryGroup ()

@property (nonatomic, weak) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;

@end

@implementation MADTableViewCellQueryGroup

+ (CGFloat)defaultHeight {
    return 88.0;
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
