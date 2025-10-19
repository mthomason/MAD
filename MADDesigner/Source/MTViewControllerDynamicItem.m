//
//  MTViewControllerDynamicItem.m
//  MAD
//
//  Created by Michael Thomason on 11/25/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerDynamicItem.h"

@implementation MTViewControllerDynamicItem

- (void)setCenter:(CGPoint)center {
	self.view.center = center;
}

- (void)setBounds:(CGRect)bounds {
	self.view.bounds = bounds;
}

- (void)setTransform:(CGAffineTransform)transform {
	self.view.transform = transform;
}

- (CGPoint)center {
	return self.view.center;
}

- (CGRect)bounds {
	return self.view.bounds;
}

- (CGAffineTransform)transform {
	return self.view.transform;
}

@end
