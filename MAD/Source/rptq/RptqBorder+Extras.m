//
//  RptqBorder+Extras.m
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqBorder+Extras.h"
#import "RptqDirectionalAsymmetry.h"
#import "RptqDirectionalProperty.h"

#import <Foundation/NSException.h>
#import <CoreData/NSEntityDescription.h>

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
	[super awakeFromInsert];
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	NSAssert(managedObjectContext != nil, @"Managed object context is nil");
	if (self.width == nil) {
		self.width = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDirectionalAsymmetry class])
												   inManagedObjectContext: managedObjectContext];
	}
	if (self.style == nil) {
		self.style = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDirectionalProperty class])
												   inManagedObjectContext: managedObjectContext];
	}
}

@end
