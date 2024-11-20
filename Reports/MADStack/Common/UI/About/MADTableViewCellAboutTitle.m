//
//  MADTableViewCellAboutTitle.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADTableViewCellAboutTitle.h"
#import <UIKit/UILabel.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADTableViewCellAboutTitle

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
    self.detailTextLabel.text = @"";
    self.tintColor = [MADColorEverydayApps newColorBlackTwentyFivePercent];
    self.textLabel.numberOfLines = 0;
}

@end
