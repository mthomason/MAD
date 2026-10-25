//
//  MADModelTable.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADModelTable.h"
#import <MAD/RptqStoreContext.h>
#import <MADFoundation/madlog.h>

#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>


#import <MADFoundation/MADStringUtilities.h>

#import "MADModelField.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#pragma mark -
#pragma mark MADModelTable

@implementation MADModelTable {
	BOOL _queryable;
	NSString *_name;
	NSMutableOrderedSet <NSNumber *> *_fieldIDs;
	NSMutableDictionary <NSNumber *, MADModelField *> *_fields;
}

@synthesize managedObjectContext = _managedObjectContext;

@dynamic fields;
@dynamic fieldIDs;
@dynamic name;

- (void)dealloc {
	[_fieldIDs removeAllObjects];
	[_fields removeAllObjects];
	_inDatabase = nil;
	_managedObjectContext = nil;
}

- (instancetype)initWithIdentifier:(int64_t)identifier {
	if (self = [self initWithIdentifier:identifier
				   managedObjectContext:nil]) {

	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(RptqStoreContext *)context {
	if (self = [self initWithIdentifier:identifier
				   managedObjectContext:context
								   name:nil
							  queryable:NO]) {
		
	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(RptqStoreContext *)context
							  name:(NSString *)name
						 queryable:(BOOL)queryable {
	if (self = [super initWithIdentifier:identifier]) {
		_name = name.copy;
		_queryable = queryable;
		_managedObjectContext = context;
	}
	return self;
}

- (NSString *)name {
	return _name;
}

- (NSOrderedSet <NSNumber *> *)fieldIDs {
	if (_fieldIDs.count == 0) {
		
		NSMutableOrderedSet <NSNumber *> *fieldIDs;
		fieldIDs = [[NSMutableOrderedSet alloc] init];
		_fieldIDs = fieldIDs;
		
		NSMutableDictionary <NSNumber *, MADModelField *> *fields;
		fields = [[NSMutableDictionary alloc] init];
		_fields = fields;
		
		[self update];
	}
	return _fieldIDs;
}

- (NSDictionary <NSNumber *, MADModelField *> *)fields {
	if (_fields.count == 0) {
		
		NSMutableOrderedSet <NSNumber *> *fieldIDs;
		fieldIDs = [[NSMutableOrderedSet alloc] init];
		_fieldIDs = fieldIDs;

		NSMutableDictionary <NSNumber *, MADModelField *> *fields;
		fields = [[NSMutableDictionary alloc] init];
		_fields = fields;
		
		[self update];
	}
	return _fields;
}

- (void)update {
	RptqStoreContext *managedObjectContext = _managedObjectContext;
	// The pre-migration fetch sorted by name; the store keeps insertion order,
	// so the sort is restored here.  See docs/project/BUGS.md "The milestone-(a) model
	// rewrites dropped the schema sort orders".
	NSSortDescriptor *sortByFieldName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *schemaFields = [[managedObjectContext objectsForEntity:NSStringFromClass([RptqDatabaseSchemaField class])]
							 sortedArrayUsingDescriptors:@[ sortByFieldName ]];

	NSMutableOrderedSet <NSNumber *> *fieldIDs = [[NSMutableOrderedSet alloc] init];
	NSMutableDictionary <NSNumber *, MADModelField *> *fields = [[NSMutableDictionary alloc] init];

	for (RptqDatabaseSchemaField *schemaField in schemaFields) {
		if (schemaField.inTable.identifier != self.identifier) continue;
		MADModelField *field = [[MADModelField alloc] initWithIdentifier: schemaField.identifier
														   isPrimaryKey: schemaField.primaryKey
															   dataType: schemaField.dataType
														 dataTypeNative: schemaField.dataTypeNative
															   decimals: schemaField.decimals
																  width: schemaField.width
																   name: schemaField.name];
		[fieldIDs addObject:@(schemaField.identifier)];
		[fields setObject:field forKey:@(schemaField.identifier)];
	}
	_fields = fields;
	_fieldIDs = fieldIDs;
}

/*- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	[debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
	[debug appendFormat:@"ID:\t%@\n", self.objectID];
	[debug appendFormat:@"Name:\t%@", _name];
	[debug appendFormat:@"Field:\t%@", self.fields];
	return debug;
}*/

@end
