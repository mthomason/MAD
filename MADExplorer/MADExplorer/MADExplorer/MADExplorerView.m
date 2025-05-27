//
//  MADFileExplorerView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
