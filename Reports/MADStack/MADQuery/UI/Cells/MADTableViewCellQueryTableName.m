//
//  UITableViewCellTableName.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewCellQueryTableName.h"
#import <UIKit/UILabel.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "Constants.h"

@implementation MADTableViewCellQueryTableName

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.textLabel.font = font;
    self.textLabel.backgroundColor = [UIColor whiteColor];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.indentationLevel = 1;
    self.tintColor = [MADColorEverydayApps newColorBlue];
    self.backgroundColor = [UIColor whiteColor];
    self.textLabel.numberOfLines = 0;
}

+ (CGFloat)defaultHeight {
    return 44.0000f;
}

@end
