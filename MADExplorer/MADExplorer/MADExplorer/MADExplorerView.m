//
//  MADFileExplorerView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADExplorerView.h"
#import <UIKit/UIView.h>
#import <UIKit/UITapGestureRecognizer.h>

@implementation MADExplorerView

+ (void)initialize {
	[super initialize];
	if (self == [MADExplorerView self]) {
		@autoreleasepool {
			[[MADExplorerView appearance] setBackgroundColor: [UIColor systemGroupedBackgroundColor]];
		}
	}
}

/*

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.scrollIndicatorInsets = self.contentInset;
	}
	return self;
}

*/

@end
