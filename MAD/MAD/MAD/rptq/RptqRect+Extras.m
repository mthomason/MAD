//
//  RptqRect+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqRect+Extras.h"
#import "RptqPoint.h"
#import "RptqSize.h"
#import "madlog.h"
#import <CoreData/NSEntityDescription.h>
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
	[super awakeFromInsert];
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if (managedObjectContext == nil) {
		os_log_error(OS_LOG_DEFAULT, "%s: Managed object context is nil", __PRETTY_FUNCTION__);
		return;
	}
	if (self.origin == nil) {
		self.origin = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqPoint class])
													inManagedObjectContext: managedObjectContext];
	}
	if (self.size == nil) {
		self.size = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqSize class])
												  inManagedObjectContext: managedObjectContext];
	}
}

- (CGRect)frame {
	return CGRectMake(self.origin.x, self.origin.y, self.size.width, self.size.height);
}

@end
