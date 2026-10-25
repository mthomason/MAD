//
//  RptqDocumentElementLabel+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocumentElementLabel+Extras.h"
#import "RptqDocumentElement.h"

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import "RptqDocumentElement+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementLabel (Extras)

#pragma mark - Overrides

- (NSString *)designerRepresentationText {
	return self.text;
}

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(int64_t)objectId fromObjectContext:(RptqStoreContext *)managedObjectContext {
	RptqObject *result = [managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:objectId];
	return (RptqDocumentElementLabel *)result;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:             %lldld\n", self.identifier];
	[description appendFormat:@"Text:                   %@\n", self.text];
	[description appendFormat:@"*********"];
	return description;
}

@end
