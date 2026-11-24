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
#import "RptqQueryTable.h"
#import "RptqQuery.h"

@implementation MADQueryActiveQueryFields

- (instancetype)initWithContext:(RptqStoreContext *)context {
	return [self initWithContext:context query:nil];
}

- (instancetype)initWithContext:(RptqStoreContext *)context query:(RptqQuery *)query {
	return [self initWithContext:context query:query requiredFields:nil];
}

- (instancetype)initWithContext:(RptqStoreContext *)context
						  query:(RptqQuery *)query
				 requiredFields:(NSSet<RptqQueryField *> *)requiredFields {

	if (self = [super init]) {
		NSArray *objects;
		NSMutableSet *queryFields = [[NSMutableSet alloc] init];

		// A field belongs to the selected query through its query table; a field
		// with no owning table cannot appear in any query's projection.
		void (^addField)(RptqQueryField *) = ^(RptqQueryField *queryField) {
			if (queryField == nil) return;
			if (query != nil) {
				RptqQuery *owner = queryField.inQueryTable.inQuery;
				if (owner == nil || owner.identifier != query.identifier) return;
			}
			[queryFields addObject: queryField];
		};

		// Barcodes
		objects = [self objectOfType: [RptqDocumentElementBarcode class]
						   inContext: context];
		for (RptqDocumentElementBarcode *dataField in objects) {
			addField(dataField.referencesField1);
			addField(dataField.referencesField2);
		}

		// Data labels
		objects = [self objectOfType: [RptqDocumentElementLabelDataField class]
						   inContext: context];
		for (RptqDocumentElementLabelDataField *dataField in objects) {
			addField(dataField.referencesQueryField);
		}

		// Aggregate
		objects = [self objectOfType: [RptqDocumentElementAggregate class]
						   inContext: context];
		for (RptqDocumentElementAggregate *dataField in objects) {
			addField(dataField.aggregateField);
		}

		// Query links
		objects = [self objectOfType: [RptqQueryLinks class]
						   inContext: context];
		for (RptqQueryLinks *queryLink in objects) {
			addField(queryLink.hasLeftField);
			addField(queryLink.hasRightField);
		}

		// Query groups
		objects = [self objectOfType: [RptqQueryGroup class]
						   inContext: context];
		for (RptqQueryGroup *queryGroup in objects) {
			addField(queryGroup.hasField);
		}

		// Fields a downstream consumer requires: projected even without a report
		// element, link or group referencing them.  They are scoped to the query the
		// same way the element-driven fields are.
		for (RptqQueryField *requiredField in requiredFields) {
			if (requiredField == nil) continue;
			if (query != nil) {
				RptqQuery *owner = requiredField.inQueryTable.inQuery;
				if (owner == nil || owner.identifier != query.identifier) continue;
			}
			[queryFields addObject: requiredField];
		}

		self.queryFields = queryFields;

	}
	return self;
}

- (NSArray *)objectOfType:(Class)managedObjectType inContext:(RptqStoreContext *)context {
	return [context objectsForEntity:NSStringFromClass(managedObjectType)];
}

@end
