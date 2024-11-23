//
//  RptqRect+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqRect+Extras.h"

#import <CoreData/NSEntityDescription.h>
#import <CoreGraphics/CGGeometry.h>

#import "RptqPoint.h"
#import "RptqSize.h"

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
	if (self.origin == nil) {
		NSString *name = NSStringFromClass([RptqPoint class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.origin = [NSEntityDescription insertNewObjectForEntityForName: name
													inManagedObjectContext: managedObjectContext];
	}
	if (self.size == nil) {
		NSString *name = NSStringFromClass([RptqSize class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.size = [NSEntityDescription insertNewObjectForEntityForName: name
												  inManagedObjectContext: managedObjectContext];
	}
}

- (CGRect)frame {
	return CGRectMake(self.origin.x, self.origin.y, self.size.width, self.size.height);
}

@end
