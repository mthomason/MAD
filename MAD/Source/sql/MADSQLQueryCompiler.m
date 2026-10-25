//
//  MADSQLQueryCompiler.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSQLQueryCompiler.h"

#import "MADSQLCompileError.h"

#import "RptqStoreContext.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementAggregate.h"

@interface MADSQLQueryCompiler ()

@property (nonatomic, strong) MADSQLQueryPlan *plan;
@property (nonatomic, strong) id<MADSQLQueryDocument> document;
@property (nonatomic, strong) RptqQuery *query;
@property (nonatomic, strong) RptqStoreContext *context;

@end

@implementation MADSQLQueryCompiler

- (instancetype)initWithPlan:(MADSQLQueryPlan *)plan
					document:(id<MADSQLQueryDocument>)document
					   query:(RptqQuery *)query
					 context:(RptqStoreContext *)context {
	self = [super init];
	if (!self) return nil;
	_plan = plan;
	_document = document;
	_query = query;
	_context = context;
	return self;
}

#pragma mark - The apply

- (BOOL)applyWithError:(NSError * __autoreleasing *)error {
	if (![self conflictCheckWithError:error]) return NO;

	// Delete, in the order the dependencies demand: groups first (their
	// sections detach through the document), then links and predicates, then
	// the tables the plan does not keep -- with their fields, so no row is left
	// behind.
	for (RptqQueryGroup *group in self.query.hasQueryGroups.allObjects) {
		[self.document removeGroupWitObjectID:group.identifier fromManagedObjectContext:self.context];
	}
	[self.document deleteAllQueryLinksInContent:self.context];
	[self.document deleteAllQueryPredicatesInContent:self.context];

	NSSet<NSNumber *> *keptSchemaTables = [self keptSchemaTableIdentifiers];
	for (RptqQueryTable *table in self.query.hasQueryTables.allObjects) {
		if ([keptSchemaTables containsObject:@(table.databaseSchemaTable.identifier)]) continue;
		[self.document deleteDatafieldsRelatedToTable:table.identifier inContent:self.context];
		[self.document deleteAggregateFieldRelatedToTable:table.identifier inContent:self.context];
		for (RptqQueryField *field in table.hasQueryFields) {
			[self.context deleteObject:field error:NULL];
		}
		[self.query removeHasQueryTablesObject:table];
		[self.context deleteObject:table error:NULL];
	}

	// The plan's tables: a copy the query already holds is kept, fields and
	// all; a missing copy is created the way the designer's add-table flow
	// does, one query field per schema field.
	NSMutableDictionary<NSString *, RptqQueryTable *> *queryTableByPlan = [NSMutableDictionary dictionary];
	for (MADSQLPlanTable *planTable in self.plan.tables) {
		RptqQueryTable *existing = nil;
		for (RptqQueryTable *candidate in self.query.hasQueryTables) {
			if (candidate.databaseSchemaTable == planTable.schemaTable && candidate.dropIndex == planTable.dropIndex) {
				existing = candidate;
				break;
			}
		}
		if (existing != nil) {
			queryTableByPlan[planTable.alias.lowercaseString] = existing;
			continue;
		}

		RptqDatabase *database = planTable.schemaTable.inDatabase;
		RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:planTable.schemaTable
																		database:database
														  forManagedObjectContext:self.context];
		NSMutableSet<RptqQueryField *> *fields = [NSMutableSet setWithCapacity:planTable.schemaTable.hasFields.count];
		for (RptqDatabaseSchemaField *schemaField in planTable.schemaTable.hasFields) {
			RptqQueryField *queryField = [RptqQueryField newQueryField:self.context];
			queryField.inQueryTable = queryTable;
			queryField.databaseSchemaField = schemaField;
			[fields addObject:queryField];
		}
		queryTable.hasQueryFields = fields;
		[self.query addHasQueryTablesObject:queryTable];
		queryTableByPlan[planTable.alias.lowercaseString] = queryTable;
	}

	// Create: links, predicates, groups -- the same factories the query UI
	// calls.
	for (MADSQLPlanLink *planLink in self.plan.links) {
		RptqQueryTable *leftTable = queryTableByPlan[planLink.leftTable.alias.lowercaseString];
		RptqQueryTable *rightTable = queryTableByPlan[planLink.rightTable.alias.lowercaseString];
		RptqQueryField *leftField = [self queryFieldNamed:planLink.leftField inQueryTable:leftTable];
		RptqQueryField *rightField = [self queryFieldNamed:planLink.rightField inQueryTable:rightTable];
		RptqQueryLinks *link = [RptqQueryLinks newQueryLinksWithLeftField:leftField
															  rightField:rightField
																joinType:planLink.type
													managedObjectContext:self.context];
		[self.query addHasQueryLinksObject:link];
	}

	for (MADSQLPlanPredicate *planPredicate in self.plan.predicates) {
		RptqQueryPredicate *predicate = [self predicateForPlanPredicate:planPredicate
														 queryTableByPlan:queryTableByPlan
																	error:error];
		if (predicate == nil) return NO;
		[self.query addHasQueryPredicateObject:predicate];
	}

	for (MADSQLPlanGroup *planGroup in self.plan.groups) {
		RptqQueryTable *queryTable = queryTableByPlan[planGroup.table.alias.lowercaseString];
		RptqQueryField *field = [self queryFieldNamed:planGroup.field inQueryTable:queryTable];
		[self.document addQueryGroupWithQueryField:field.identifier andSortOrder:planGroup.sortOrder];
	}

	// The entered text is part of the document -- and only of a document the
	// apply succeeded on.
	self.query.sqlSourceText = self.plan.sourceText;

	return [self.context save:error];
}

#pragma mark - The conflict check

// §6.3: a designer element (label-data, aggregate or barcode) or a group
// section that references a field of a table the plan drops blocks the apply.
// The error names the elements; nothing has been touched.
- (BOOL)conflictCheckWithError:(NSError * __autoreleasing *)error {
	NSMutableSet<RptqQueryField *> *droppedFields = [NSMutableSet set];
	NSMutableSet<RptqQueryTable *> *droppedTables = [NSMutableSet set];
	NSSet<NSNumber *> *keptSchemaTables = [self keptSchemaTableIdentifiers];
	for (RptqQueryTable *table in self.query.hasQueryTables) {
		if ([keptSchemaTables containsObject:@(table.databaseSchemaTable.identifier)]) continue;
		[droppedTables addObject:table];
		for (RptqQueryField *field in table.hasQueryFields) {
			[droppedFields addObject:field];
		}
	}
	if (droppedFields.count == 0) return YES;

	NSMutableArray<NSString *> *conflicts = [NSMutableArray array];

	for (RptqDocumentElementLabelDataField *element in [self.context objectsForEntity:@"RptqDocumentElementLabelDataField"]) {
		if ([droppedFields containsObject:element.referencesQueryField]) {
			[conflicts addObject:[self nameForElement:element]];
		}
	}
	for (RptqDocumentElementAggregate *element in [self.context objectsForEntity:@"RptqDocumentElementAggregate"]) {
		if ([droppedFields containsObject:element.aggregateField]) {
			[conflicts addObject:[self nameForElement:element]];
		}
	}
	for (RptqDocumentElementBarcode *element in [self.context objectsForEntity:@"RptqDocumentElementBarcode"]) {
		if ([droppedFields containsObject:element.referencesField1] || [droppedFields containsObject:element.referencesField2]) {
			[conflicts addObject:[self nameForElement:element]];
		}
	}
	for (RptqQueryGroup *group in self.query.hasQueryGroups) {
		if ([droppedTables containsObject:group.hasField.inQueryTable]) {
			[conflicts addObject:[[NSString alloc] initWithFormat:@"group %lld's header and footer sections", (long long)group.identifier]];
		}
	}

	if (conflicts.count == 0) return YES;

	if (error) {
		NSString *message = [[NSString alloc] initWithFormat:
			@"This field is used by %@ in the designer; the query was not changed.", [conflicts componentsJoinedByString:@", "]];
		*error = [MADSQLCompileError errorWithCode:MADSQLCompileErrorDesignerConflict
											  line:0
											column:0
										   message:message];
	}
	return NO;
}

- (NSString *)nameForElement:(RptqDocumentElement *)element {
	return [[NSString alloc] initWithFormat:@"%@ #%lld", element.entity, (long long)element.identifier];
}

- (NSSet<NSNumber *> *)keptSchemaTableIdentifiers {
	NSMutableSet<NSNumber *> *kept = [NSMutableSet setWithCapacity:self.plan.tables.count];
	for (MADSQLPlanTable *planTable in self.plan.tables) {
		[kept addObject:@(planTable.schemaTable.identifier)];
	}
	return kept;
}

#pragma mark - Factories

- (RptqQueryField *)queryFieldNamed:(NSString *)schemaFieldName inQueryTable:(RptqQueryTable *)queryTable {
	for (RptqQueryField *field in queryTable.hasQueryFields) {
		if ([field.databaseSchemaField.name.lowercaseString isEqualToString:schemaFieldName.lowercaseString]) {
			return field;
		}
	}
	return nil;
}

- (RptqQueryPredicate *)predicateForPlanPredicate:(MADSQLPlanPredicate *)planPredicate
								  queryTableByPlan:(NSDictionary<NSString *, RptqQueryTable *> *)queryTableByPlan
											error:(NSError * __autoreleasing *)error {
	RptqQueryField *leftField = planPredicate.leftTable != nil ?
		[self queryFieldNamed:planPredicate.leftField inQueryTable:queryTableByPlan[planPredicate.leftTable.alias.lowercaseString]] : nil;
	RptqQueryField *rightField = planPredicate.rightTable != nil ?
		[self queryFieldNamed:planPredicate.rightField inQueryTable:queryTableByPlan[planPredicate.rightTable.alias.lowercaseString]] : nil;

	if (leftField != nil && rightField != nil) {
		return [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:leftField.identifier
														comparsonOperator:planPredicate.operator
														  andRightFieldID:rightField.identifier
												  forManagedObjectContext:self.context
																	error:error];
	}
	if (leftField != nil && planPredicate.rightLiteral != nil) {
		return [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:leftField.identifier
														comparsonOperator:planPredicate.operator
															andRightValue:planPredicate.rightLiteral
												  forManagedObjectContext:self.context
																	error:error];
	}
	if (planPredicate.leftLiteral != nil && rightField != nil) {
		return [RptqQueryPredicate newQueryPredicateFactoryWithLeftValue:planPredicate.leftLiteral
													  comparsonOperator:planPredicate.operator
														andRightFieldID:rightField.identifier
												forManagedObjectContext:self.context
																  error:error];
	}
	return [RptqQueryPredicate newQueryPredicateFactoryWithLeftValue:planPredicate.leftLiteral
												  comparsonOperator:planPredicate.operator
													  andRightValue:planPredicate.rightLiteral
											forManagedObjectContext:self.context
															  error:error];
}

@end
