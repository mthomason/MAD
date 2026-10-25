//
//  UITableViewCellQueryLink.m
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADTableViewCellQueryLink.h"
#import <UIKit/UILabel.h>
#import "Constants.h"

@implementation MADTableViewCellQueryLink

+ (CGFloat)defaultHeight {
	return 50.0;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
			  reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		self.textLabel.numberOfLines = 0;
		self.textLabel.textColor = [UIColor labelColor];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.textLabel.numberOfLines = 0;
		self.textLabel.textColor = [UIColor labelColor];
	}
	return self;
}

@end
