//
//  RptqBorder+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqBorder+Extras.h"
#import <CoreData/NSEntityDescription.h>
#import "RptqDirectionalAsymmetry.h"
#import "RptqDirectionalProperty.h"

@implementation RptqBorder (Extras)

+ (NSString *)keyWidth {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(width));
	return key;
}

+ (NSString *)keyStyle {
	static NSString *key = nil;
	if (key == nil) key = NSStringFromSelector(@selector(style));
	return key;
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	if (self.width == nil) {
		NSString *name = NSStringFromClass([RptqDirectionalAsymmetry class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.width = [NSEntityDescription insertNewObjectForEntityForName: name
												   inManagedObjectContext: managedObjectContext];
	}
	if (self.style == nil) {
		NSString *name = NSStringFromClass([RptqDirectionalProperty class]);
		NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
		self.style = [NSEntityDescription insertNewObjectForEntityForName: name
												  inManagedObjectContext: managedObjectContext];
	}
}

@end
