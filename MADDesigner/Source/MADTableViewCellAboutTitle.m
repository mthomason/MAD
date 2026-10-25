//
//  MADTableViewCellAboutTitle.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADTableViewCellAboutTitle.h"
#import <UIKit/UILabel.h>

@implementation MADTableViewCellAboutTitle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		self.textLabel.textColor = [UIColor labelColor];
		self.detailTextLabel.text = @"";
		self.textLabel.numberOfLines = 0;
	}
	return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.textLabel.textColor = [UIColor labelColor];
		self.detailTextLabel.text = @"";
		self.textLabel.numberOfLines = 0;
	}
	return self;
}

@end
