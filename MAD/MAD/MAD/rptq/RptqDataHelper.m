//
//  RptqDataHelper.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDataHelper.h"
#import "madlog.h"

#import <objc/objc.h>

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSUUID.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSExpression.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>

@implementation RptqDataHelper

static NSMutableDictionary *_autoincrementMap;

+ (void)cleanup {
	[_autoincrementMap removeAllObjects];
	_autoincrementMap = nil;
}

+ (int64_t)nextIdentifierForClass:(Class)class managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	if (_autoincrementMap == nil) {
		_autoincrementMap = [[NSMutableDictionary alloc] init];
	}

	int64_t identifier64 = 0;
	NSString *className = NSStringFromClass(class);
	NSNumber *idNumber = nil;
	idNumber = [_autoincrementMap objectForKey:className];
	if (idNumber != nil) {
		identifier64 = idNumber.longLongValue + 1;
	} else {
		
		NSExpressionDescription *edIdentifier = [[NSExpressionDescription alloc] init];
		edIdentifier.name = @"ID";
		edIdentifier.expression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))];
		edIdentifier.expressionResultType = NSInteger64AttributeType;
		
		NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass(class)];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: NSStringFromSelector(@selector(identifier)) ascending: NO];
		NSArray <NSSortDescriptor *> *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
		
		NSArray *properties = [[NSArray alloc] initWithObjects:edIdentifier, nil];
		request.propertiesToFetch = properties;
		request.sortDescriptors = sortDescriptors;
		request.fetchLimit = 1;
		request.resultType = NSDictionaryResultType;
		
		NSError *error = nil;
		NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
		if (error != nil) {
			os_log_error(GetMadLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
		}
				
		if (fetchResults.count > 0) {
			NSNumber *identifierNumber;
			if ((identifierNumber = [[fetchResults firstObject] objectForKey:@"ID"]) != nil) {
				CFNumberGetValue((__bridge CFNumberRef)(identifierNumber), kCFNumberSInt64Type, &identifier64);
			}
		}
		identifier64++;
	}
	idNumber = @(identifier64);
	[_autoincrementMap setObject:idNumber forKey:className];
	return identifier64;

}

- (void)identifier { }

@end
