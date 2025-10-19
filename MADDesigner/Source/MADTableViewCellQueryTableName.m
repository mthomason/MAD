//
//  UITableViewCellTableName.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADTableViewCellQueryTableName.h"
#import <UIKit/UILabel.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "Constants.h"

@implementation MADTableViewCellQueryTableName

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		self.textLabel.textColor = [UIColor labelColor];
		self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.indentationLevel = 1;
		self.textLabel.numberOfLines = 0;
	}
	return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.textLabel.textColor = [UIColor labelColor];
		self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.indentationLevel = 1;
		self.textLabel.numberOfLines = 0;
	}
	return self;
}

+ (CGFloat)defaultHeight {
	return 44.0;
}

@end
