//
//  RptqSize+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqSize+Extras.h"

@implementation RptqSize (Extras)

static NSString *keyWidth = nil;
static NSString *keyHeight = nil;

+ (void)load {
	keyWidth = NSStringFromSelector(@selector(width));
	keyHeight = NSStringFromSelector(@selector(height));
}

+ (NSString *)keyWidth { return keyWidth; }
+ (NSString *)keyHeight { return keyHeight; }

@end
