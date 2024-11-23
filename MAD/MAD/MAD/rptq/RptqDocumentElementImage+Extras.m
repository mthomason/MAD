//
//  RptqDocumentElementImage+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementImage+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementImage (Extras)

#pragma mark - Overrides

- (NSString *)designerRepresentationText {
	return @"image";
}

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(NSManagedObjectID *)objectId
					fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
	NSManagedObject *result = [managedObjectContext objectWithID:objectId];
	return (RptqDocumentElementImage *)result;
}

- (id)debugQuickLookObject {
	return self.image;
}

@end
