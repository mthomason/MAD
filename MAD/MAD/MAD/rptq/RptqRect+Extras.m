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

+ (NSString *)keyOrigin {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(origin));
	return key;
}

+ (NSString *)keySize {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(size));
	return key;
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if (managedObjectContext == nil) {
		os_log_error(OS_LOG_DEFAULT, "Managed object context is nil");
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

- (CGRect)frame { return CGRectMake(self.origin.x, self.origin.y, self.size.width, self.size.height); }

@end
