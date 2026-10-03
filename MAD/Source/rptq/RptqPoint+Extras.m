//
//  RptqPoint+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqStoreContext.h"
#import "RptqPoint+Extras.h"

@implementation RptqPoint (Extras)

static NSString *keyX = nil;
static NSString *keyY = nil;

+ (void)load {
	keyX = NSStringFromSelector(@selector(x));
	keyY = NSStringFromSelector(@selector(y));
}

+ (NSString *)keyX {
	return keyX;
}

+ (NSString *)keyY {
	return keyY;
}

@end
