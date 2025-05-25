//
//  UITableViewCellInstruction.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADTableViewCellQueryInstructions.h"
#import <UIKit/UILabel.h>

@implementation MADTableViewCellQueryInstructions

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

	if (self = [super initWithCoder:aDecoder]) {
		
		[self setBackgroundView: nil];
		[self setSelectedBackgroundView: nil];
		[self setBackgroundColor:[UIColor systemGroupedBackgroundColor]];
		self.textLabel.textColor = [UIColor labelColor];

	}
	return self;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style
			  reuseIdentifier:(NSString *)reuseIdentifier {

	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		
		[self setBackgroundView: nil];
		[self setSelectedBackgroundView: nil];
		[self setBackgroundColor:[UIColor systemGroupedBackgroundColor]];
		self.textLabel.textColor = [UIColor labelColor];

		
	}
	return self;
	
}

+ (CGFloat)defaultHeight {
	return 44.0;
}

@end
