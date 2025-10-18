//
//  RptqDocumentElementLabelDataField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementLabelDataField+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocument.h"
#import "RptqDataHelper.h"

#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

@implementation RptqDocumentElementLabelDataField (Extras)

#pragma mark - Overrides

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(NSManagedObjectID *)objectId
					fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
	NSManagedObject *result = [managedObjectContext objectWithID:objectId];
	NSAssert(result != nil, @"Could not get managed object.");
	return (RptqDocumentElementLabelDataField *)result;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Text:                   %@\n", self.text];
	[description appendFormat:@"Table:                  %@\n", self.tableID];
	[description appendFormat:@"Field:                  %@\n", self.fieldID];
	[description appendFormat:@"*********"];
	return description;
}

- (NSString *)designerRepresentationText {
	return [self referencesQueryField].toStringReverse;
}


@end
