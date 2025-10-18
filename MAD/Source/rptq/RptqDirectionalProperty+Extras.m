//
//  RptqDirectionalProperty+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDirectionalProperty+Extras.h"

@implementation RptqDirectionalProperty (Extras)

static NSString *keyTop = nil;
static NSString *keyBottom = nil;
static NSString *keyLeft = nil;
static NSString *keyRight = nil;

+ (void)load {
	keyTop = NSStringFromSelector(@selector(top));
	keyBottom = NSStringFromSelector(@selector(bottom));
	keyLeft = NSStringFromSelector(@selector(left));
	keyRight = NSStringFromSelector(@selector(right));
}

+ (NSString *)keyTop { return keyTop; }
+ (NSString *)keyBottom { return keyBottom; }
+ (NSString *)keyLeft { return keyLeft; }
+ (NSString *)keyRight { return keyRight; }

@end
