//
//  MADQueryVisualizationSchemaView.m
//  MAD Designer
//
//  Created by Michael on 1/26/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryVisualizationSchemaView.h"

@implementation MADQueryVisualizationSchemaView

@synthesize identifier = _identifier;
@dynamic center;
@dynamic bounds;
@dynamic transform;

- (instancetype)init {
	if (self = [super init]) {
		[self setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin |
								   UIViewAutoresizingFlexibleBottomMargin |
								   UIViewAutoresizingFlexibleLeftMargin |
								   UIViewAutoresizingFlexibleRightMargin];
		[self setTranslatesAutoresizingMaskIntoConstraints: YES];
		[self setAutoresizesSubviews: NO];
	}
	return self;
}

- (id <NSCopying>)key {
	return @(self.identifier);
}

@end
