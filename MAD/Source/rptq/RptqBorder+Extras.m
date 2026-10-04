//
//  RptqBorder+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqStoreContext.h"
#import "RptqBorder+Extras.h"
#import "RptqDirectionalAsymmetry.h"
#import "RptqDirectionalProperty.h"

#import <Foundation/NSException.h>
@implementation RptqBorder (Extras)

static NSString *keyWidth = nil;
static NSString *keyStyle = nil;

+ (void)load {
	keyWidth = NSStringFromSelector(@selector(width));
	keyStyle = NSStringFromSelector(@selector(style));
}

+ (NSString *)keyWidth { return keyWidth; }
+ (NSString *)keyStyle { return keyStyle; }

- (void)awakeFromInsert {
	RptqStoreContext *context = self.storeContext;
	if (self.width == nil) {
		self.width = (RptqDirectionalAsymmetry *)[context insertObjectForEntity:NSStringFromClass([RptqDirectionalAsymmetry class]) identifier:0];
	}
	if (self.style == nil) {
		self.style = (RptqDirectionalProperty *)[context insertObjectForEntity:NSStringFromClass([RptqDirectionalProperty class]) identifier:0];
	}
}

@end
