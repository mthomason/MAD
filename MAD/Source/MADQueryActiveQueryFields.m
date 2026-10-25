//
//  MADQueryActiveQueryFields.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryActiveQueryFields.h"
#import <MAD/RptqStoreContext.h>
#import <MADFoundation/madlog.h>

#import <Foundation/NSPredicate.h>

#import "MADDocumentObjectType.h"

#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqQueryGroup.h"
#import "RptqQuery.h"

@implementation MADQueryActiveQueryFields

- (instancetype)initWithContext:(RptqStoreContext *)context {
	
	if (self = [super init]) {
		NSArray *objects;
		
		// Barcodes
		objects = [self objectOfType: [RptqDocumentElementBarcode class]
						   inContext: context];
		
		NSMutableSet *queryFields = [[NSMutableSet alloc] init];
		for (RptqDocumentElementBarcode *dataField in objects) {
			RptqQueryField *queryField = dataField.referencesField1;
			if (queryField != nil) {
				[queryFields addObject:queryField];
			}
			RptqQueryField *queryField2 = dataField.referencesField2;
			if (queryField2 != nil) {
				[queryFields addObject:queryField2];
			}
		}

		// Data labels
		objects = [self objectOfType: [RptqDocumentElementLabelDataField class]
						   inContext: context];

		for (RptqDocumentElementLabelDataField *dataField in objects) {
			RptqQueryField *queryField = dataField.referencesQueryField;
			if (queryField != nil) {
				[queryFields addObject:queryField];
			}
		}
		
		// Aggregate
		objects = [self objectOfType: [RptqDocumentElementAggregate class]
						   inContext: context];
		
		for (RptqDocumentElementAggregate *dataField in objects) {
			RptqQueryField *queryField = dataField.aggregateField;
			if (queryField != nil) {
				[queryFields addObject:queryField];
			}
		}
		
		// Query links
		objects = [self objectOfType: [RptqQueryLinks class]
						   inContext: context];
		
		for (RptqQueryLinks *queryLink in objects) {
			RptqQueryField *queryFieldLeft = queryLink.hasLeftField;
			if (queryFieldLeft != nil) {
				[queryFields addObject:queryFieldLeft];
			}
			RptqQueryField *queryFieldRight = queryLink.hasRightField;
			if (queryFieldRight != nil) {
				[queryFields addObject:queryFieldRight];
			}
		}
		
		// Query groups
		objects = [self objectOfType: [RptqQueryGroup class]
						   inContext: context];
		
		for (RptqQueryGroup *queryGroup in objects) {
			RptqQueryField *queryField = queryGroup.hasField;
			if (queryField != nil) {
				[queryFields addObject:queryField];
			}
		}
		self.queryFields = queryFields;
		
	}
	return self;
}

- (NSArray *)objectOfType:(Class)managedObjectType inContext:(RptqStoreContext *)context {
	return [context objectsForEntity:NSStringFromClass(managedObjectType)];
}

@end
