//
//  RptqRect+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "RptqStoreContext.h"
#import "RptqRect+Extras.h"
#import "RptqPoint.h"
#import "RptqSize.h"
#import <MADFoundation/madlog.h>
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
		self.origin = (RptqPoint *)[context insertObjectForEntity:NSStringFromClass([RptqPoint class]) identifier:0];
	}
	if (self.size == nil) {
		self.size = (RptqSize *)[context insertObjectForEntity:NSStringFromClass([RptqSize class]) identifier:0];
	}
}

- (CGRect)frame {
	return CGRectMake(self.origin.x, self.origin.y, self.size.width, self.size.height);
}

@end
