//
//  RptqSize+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqSize+Extras.h"

@implementation RptqSize (Extras)

+ (NSString *)keyWidth {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(width));
	return key;
}

+ (NSString *)keyHeight {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(height));
	return key;
}

@end
