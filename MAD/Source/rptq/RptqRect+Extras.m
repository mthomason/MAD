//
//  RptqRect+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqStoreContext.h"
#import "RptqRect+Extras.h"
#import "RptqPoint.h"
#import "RptqSize.h"
#import "madlog.h"
#import <CoreGraphics/CGGeometry.h>

@implementation RptqRect (Extras)

static NSString *keyOrigin = nil;
static NSString *keySize = nil;

+ (void)load {
	keyOrigin = NSStringFromSelector(@selector(origin));
	keySize = NSStringFromSelector(@selector(size));
}

+ (NSString *)keyOrigin { return keyOrigin; }
+ (NSString *)keySize { return keySize; }

- (void)awakeFromInsert {
	RptqStoreContext *context = self.storeContext;
	if (self.origin == nil) {
		self.origin = [context insertObjectForEntity:NSStringFromClass([RptqPoint class]) identifier:0];
	}
	if (self.size == nil) {
		self.size = [context insertObjectForEntity:NSStringFromClass([RptqSize class]) identifier:0];
	}
}

- (CGRect)frame {
	return CGRectMake(self.origin.x, self.origin.y, self.size.width, self.size.height);
}

@end
