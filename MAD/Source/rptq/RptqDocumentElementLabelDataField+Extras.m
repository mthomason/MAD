//
//  RptqDocumentElementLabelDataField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
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

@implementation RptqDocumentElementLabelDataField (Extras)

#pragma mark - Overrides

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(int64_t)objectId
					fromObjectContext:(RptqStoreContext *)managedObjectContext {
	RptqObject *result = [managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:objectId];
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
