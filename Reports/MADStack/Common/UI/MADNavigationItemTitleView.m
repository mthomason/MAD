//
//  MADNavigationItemTitleView.m
//  MAD Designer
//
//  Created by Michael on 1/7/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADNavigationItemTitleView.h"
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADNavigationItemTitleView

- (instancetype)initWithTitle:(NSString *)title {
	if (self = [super initWithTitle:title]) {
		MADLabelTitle *titleView;
		self.leftItemsSupplementBackButton = YES;
		self.hidesBackButton = NO;
		titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
		titleView.text = title.copy;
		self.titleView = titleView;
	}
	return self;
}

@end
