//
//  MADQueryReport.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryFull.h"
#import <MAD/RptqStoreContext.h>


#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>

#import <MADDataStructures/MTGraph.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTEdge.h>
#import <MADDataStructures/MADAlgorithmElementProperties.h>
#import <MADDataStructures/MADAlgorithmColor.h>

#import <MADFoundation/MADDataProtocol.h>

#import "MADDocumentDataProtocol.h"

#import <MADSqlite3/MADDataTableFast.h>

#import "MADQueryCacheFullParameters.h"

#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqQueryGroup.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqDocumentElementAggregate.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import "MADQueryPredicate.h"

#import "RptqQuerySort.h"

#import "MADQueryActiveQueryFields.h"
#import "MADQuerySelectExpression.h"
#import "MADQuerySelectExpressionAllFields.h"
#import "MADQuerySelectExpressionActiveFields.h"

#import <MADAPI/MADQueryType.h>

static inline BOOL isKindOfRptqQuery(id obj);
static inline BOOL isKindOfRptqQuery(id obj) {
	return [obj isKindOfClass:[RptqQuery class]] ||
	[obj isKindOfClass:[RptqQueryField class]] ||
	[obj isKindOfClass:[RptqQueryGroup class]] ||
	[obj isKindOfClass:[RptqQueryLinks class]] ||
	[obj isKindOfClass:[RptqQueryPredicate class]] ||
	[obj isKindOfClass:[RptqQuerySort  class]] ||
	[obj isKindOfClass:[RptqQueryTable class]];
}

@interface MADQueryFull ()

@property (nonatomic, copy) NSNumber *objectID;
/// Pre-resolved composing field expressions, keyed by query-field identifier, so the
/// FROM/JOIN and WHERE builders resolve each field once and fail fast on a miss.
@property (nonatomic, copy) NSDictionary<NSNumber *, NSString *> *composingFieldExpressions;

@end

@implementation MADComposingChild
@end

@implementation MADComposingResolver {
	NSDictionary<NSNumber *, MADComposingChild *> *_childrenByIdentifier;
}

- (instancetype)initWithChildren:(NSArray<MADComposingChild *> *)children {
	if (self = [super init]) {
		NSMutableDictionary<NSNumber *, MADComposingChild *> *map = [NSMutableDictionary dictionaryWithCapacity: children.count];
		for (MADComposingChild *child in children) {
			map[@(child.queryIdentifier)] = child;
		}
		_childrenByIdentifier = map;
	}
	return self;
}

- (nullable MADComposingChild *)childForQueryIdentifier:(int64_t)identifier {
	return _childrenByIdentifier[@(identifier)];
}

- (nullable NSString *)tableReferenceForQueryTable:(RptqQueryTable *)table {
	MADComposingChild *child = [self childForQueryIdentifier: table.upstreamQuery.identifier];
	if (child == nil || child.result == nil) return nil;
	return [NSString stringWithFormat: @"%@.%@", child.attachAlias, child.result.dataTable.tableName];
}

/// The full logical key a composing field reads from its upstream child's result:
/// a leaf's `<alias>.<field>` spelling (the same key its own SELECT wrote), or a
/// composing child's output key.  Both are the column the child published.
- (nullable NSString *)logicalKeyForField:(RptqQueryField *)field inChild:(MADComposingChild *)child {
	RptqDatabaseSchemaField *schemaField = field.databaseSchemaField;
	if (schemaField == nil || child.query == nil) return nil;

	// A composing child's output columns are keyed by its output keys; match the
	// child's output field on the shared schema field.
	BOOL composingChild = child.query.hasQueryTables.anyObject.upstreamQuery != nil;
	if (composingChild) {
		for (RptqQueryTable *table in child.query.hasQueryTables) {
			for (RptqQueryField *candidate in table.hasQueryFields) {
				if (candidate.outputKey.length > 0 && candidate.databaseSchemaField.identifier == schemaField.identifier) {
					return candidate.outputKey;
				}
			}
		}
		return nil;
	}

	// A leaf child's output columns are keyed by "<queryAlias>.<schemaField>".
	int64_t tableIdentifier = schemaField.inTable.identifier;
	for (RptqQueryTable *table in child.query.hasQueryTables) {
		if (table.databaseSchemaTable.identifier == tableIdentifier) {
			return [child.database queryKey: schemaField.name table: table.queryAlias];
		}
	}
	return nil;
}

- (nullable NSString *)columnReferenceForField:(RptqQueryField *)field error:(NSError * _Nullable __autoreleasing *)error {
	MADComposingChild *child = [self childForQueryIdentifier: field.inQueryTable.upstreamQuery.identifier];
	if (child == nil || child.result == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: @"MADQuery" code: 5780 userInfo: @{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:
					NSLocalizedString(@"A composing field references an upstream query with no published result.", @"Missing upstream result in a composing query.")] }];
		}
		return nil;
	}
	NSString *logicalKey = [self logicalKeyForField: field inChild: child];
	NSString *physical = logicalKey != nil ? [child.result.dataTable columnKeyForColumnName: logicalKey] : nil;
	if (physical == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: @"MADQuery" code: 5781 userInfo: @{
				NSLocalizedDescriptionKey: [NSString stringWithFormat:
					NSLocalizedString(@"The field %@ is not present in the upstream query's result.", @"Missing composing field."),
					field.databaseSchemaField.name ?: @"<unnamed>"] }];
		}
		return nil;
	}
	// Three-part name: `att0` is the attached database, not a table, so the column
	// must be qualified through the child's physical table.
	return [NSString stringWithFormat: @"%@.%@.%@", child.attachAlias, child.result.dataTable.tableName, physical];
}

@end

@implementation MADQueryFull

@synthesize fields = _fields;
@synthesize fieldKeys = _fieldKeys;
@synthesize dataDelegate = _dataDelegate;

- (void)dealloc {
	self.dataDelegate = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithQuery: (RptqQuery *)query
				andQueryLimit: (NSUInteger)queryLimit {
	if (self = [super initWithObject:query]) {
		
		NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
		self.fieldKeys = fieldKeys;
		
		NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
		self.fields = fieldInfo;
		
		_objectID = @(query.identifier);
		_limitResults = queryLimit;
		
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter addObserver: self
						  selector: @selector(handleManagedObjectContextDidChange:)
							  name: RptqStoreContextObjectsDidChangeNotification
							object: query.storeContext];
	}
	return self;
}

- (instancetype)initWithObject:(NSDictionary *)object {
	
	NSAssert([object isKindOfClass:[NSDictionary class]],
			 @"MADQueryFull expects NSDictionary with parameters.");
	
	NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
	self.fieldKeys = fieldKeys;
	
	NSNumber *parameterScheam = [[NSNumber alloc] initWithShort: MADQueryCacheFullQuerySchema];
	NSNumber *queryLimitWrapper = object[@"MADQueryLimit"];
	NSUInteger queryLimit = queryLimitWrapper.unsignedIntegerValue;
	RptqQuery *query = object[parameterScheam];
	id result = [self initWithQuery:query andQueryLimit:queryLimit];
	return result;
}

/// Resolve the query the caller selected, by the durable identifier captured in
/// -initWithQuery:andQueryLimit:.  The store's row order is not a selection rule;
/// taking `hasQueries.anyObject` here is what made a two-query document compile
/// an arbitrary one of them.
- (nullable RptqQuery *)selectedQueryWithContext:(RptqStoreContext *)managedObjectContext
										   error:(NSError * __autoreleasing *)error {
	RptqQuery *query = (RptqQuery *)[managedObjectContext objectForEntity: NSStringFromClass([RptqQuery class])
															   identifier: self.objectID.longLongValue];
	if (query == nil && error != NULL) {
		NSString *message = NSLocalizedString(@"The query no longer exists in the document.",
											  @"The selected query was not found in the store.");
		*error = [NSError errorWithDomain: @"MADQuery"
									 code: 5775
								 userInfo: [[NSDictionary alloc] initWithObjectsAndKeys:
											message, NSLocalizedDescriptionKey, nil]];
	}
	return query;
}

- (NSString *)copySQLWithManagedObjectContext:(RptqStoreContext *)managedObjectContext
										error:(NSError * __autoreleasing *)error {
	//[super getSql:error];
	NSString *activeFields;
	activeFields = [self SQLOnlyActiveFields: YES
						managedObjectContext: managedObjectContext
									   error: error].copy;
	return activeFields;
}

- (NSString *)SQLOnlyActiveFields: (BOOL)onlyActiveFields
			 managedObjectContext: (RptqStoreContext *)managedObjectContext
							error: (NSError * __autoreleasing *)error {
	
	RptqQuery *queryObject = [self selectedQueryWithContext: managedObjectContext error: error];
	if (queryObject == nil) return @"";

	if (queryObject.hasQueryTables.count <= 0) return @"";

	NSMutableString *result = [[NSMutableString alloc] initWithString: @""];

	MADDatabase *database = self.database ?: [self.dataDelegate database];

	if (self.composingResolver != nil) {
		return [self composingSQLForQuery: queryObject
								 database: database
					managedObjectContext: managedObjectContext
									error: error];
	}

	NSString *selectPart = [database selectPartWithLimitedResults:self.limitResults];


	MADQueryPredicate *predicate = [[MADQueryPredicate alloc] initWithQueryPredicates: queryObject.hasQueryPredicate
																		  andDatabase: database];
	
	NSString *predicatePart = [predicate.sql copy];
	NSString *limitPart = [[database sqlLimitClause: _limitResults] copy];
	
	[result appendString:selectPart];
	
	//Use a graph to represent the query: verticies are tables and edges are links.
	
	MTGraph *graph = [[MTGraph alloc] init];
	NSSet *hasTables = queryObject.hasQueryTables;
	
	//Add a vertex to the graph for each table.
	for (RptqQueryTable *table in hasTables) {
		//@autoreleasepool {
		[graph addVertexWithObject: @(table.identifier)];
		//}
	}
	
	//Create an edge in the graph for each query link.
	NSSet *hasQueryLinks = queryObject.hasQueryLinks;
	NSNumber *weight = @1;
	
	MTVertex *origin, *destination;
	for (RptqQueryLinks *queryLink in hasQueryLinks) {
		
		origin =        [graph vertexForObject: @(queryLink.hasLeftField.inQueryTable.identifier)];
		destination =   [graph vertexForObject: @(queryLink.hasRightField.inQueryTable.identifier)];
		
		[graph addEdgeWithOrigin: origin
					 destination: destination
						  object: @(queryLink.identifier)
					   andWeight: weight];
	}
	
	
	// MARK: Sort the vectors topologically.
	BOOL  isDirectedAcyclicGraph = NO;
	NSAssert(graph != nil, @"Where's the graph?");
	
	NSError * __autoreleasing sortError = NULL;
	MTLinkedList *topologicalSort = [graph topologicalSortWithError:&sortError
											 isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
	
	// MARK: Error on cycles or other bad query.
	// A cycle is a bad query.  The legacy sorter reports it through
	// isDirectedAcyclicGraph and now also fills sortError in; either is a failure.
	// Propagate the sorter's own error when it has one, and synthesize one when
	// only the flag says so, so the caller never compiles a cyclic graph.
	if (sortError != nil || !isDirectedAcyclicGraph) {
		if (sortError == nil) {
			NSString *message = NSLocalizedString(@"The query contains a cycle.",
												  @"A query link graph with a cycle.");
			sortError = [NSError errorWithDomain: @"MADQuery"
											code: 5776
										userInfo: [[NSDictionary alloc] initWithObjectsAndKeys:
												   message, NSLocalizedDescriptionKey, nil]];
		}
		if (error != NULL) *error = sortError;
		[result setString:@""];
	} else {

		NSArray *topologicalSortArray = [topologicalSort toArray];


		MADQuerySelectExpression *select;
		if (onlyActiveFields) {
			NSSet <RptqQueryField *> *required = self.requiredQueryFields.count > 0
				? [NSSet setWithArray: self.requiredQueryFields] : nil;
			select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase: database
																		 query: queryObject
													   forManagedObjectContext: managedObjectContext
																			requiredFields: required];
			self.fieldKeys = ((MADQuerySelectExpressionActiveFields *)select).fieldKeys.copy;
			self.fields = ((MADQuerySelectExpressionActiveFields *)select).fields.copy;
		} else {
			// MAKR: List each field in the query.
			select = [[MADQuerySelectExpressionAllFields alloc] initWithDatabase: database
																		  tables: topologicalSortArray
														 forManagedObjectContext: managedObjectContext];
		}
		
		NSString *sqlSelect = select.sql.copy;
		
		if (sqlSelect.length > 0) {
			[result appendString:sqlSelect];
			[result appendString:MADSqlTextFromPart];
			
			NSNumber *linkDepth = @0;
			NSMutableArray <MTVertex *> *vertexArray;
			vertexArray = [[NSMutableArray alloc] initWithCapacity: topologicalSortArray.count];
			
			for (MTPair *pair in topologicalSortArray) {
				MTVertex *vertexTable = pair.former;
				if (vertexTable) {
					vertexTable.properties.algorithmColor = MTColorWhite;
					[vertexArray addObject:vertexTable];
				}
			}
			
			NSString *tableReference = [self sqlTableReferenceWithTables: vertexArray
															   linkDepth: &linkDepth
												 forManagedObjectContext: managedObjectContext];
			[result appendString: tableReference];
			
		} else {
			NSString *message = NSLocalizedString(@"Empty query while using \"only "
												  @"active fields.\" You may need to reference "
												  @"some query fields.",
												  @"Empty query while using \"only active "
												  @"fields.\" You may need to reference some "
												  @"query fields.");
			NSDictionary *errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
									   message, NSLocalizedDescriptionKey, nil];
			if (error != NULL) {
				*error = [NSError errorWithDomain: @"MADQuery"
											 code: 5774
										 userInfo: errorInfo];
			}
			[result setString:@""];
		}
		
	}
	
	if (result.length > 0) {
		[result appendString:predicatePart];
		[result appendString:limitPart];
	}
	return result;
}

/// Compile a composing node's query: the SELECT list is the node's ordered output
/// fields (resolved to the attached children), the FROM/JOIN walks the same graph as
/// any query (each composing table resolves through the resolver), and the WHERE
/// resolves its fields through the resolver.  One SQL path serves leaves and
/// composing nodes alike; the resolver is the only composing-specific piece.
- (NSString *)composingSQLForQuery:(RptqQuery *)queryObject
						  database:(MADDatabase *)database
			 managedObjectContext:(RptqStoreContext *)managedObjectContext
							 error:(NSError * __autoreleasing *)error {
	NSError *outputError = nil;
	NSArray<RptqQueryField *> *outputs = [queryObject orderedOutputFieldsWithError: &outputError];
	if (outputs == nil) {
		if (error != NULL) *error = outputError;
		return @"";
	}

	// Resolve every composing field (outputs, link sides, predicate operands) before
	// emitting any SQL, so a missing child or column fails fast rather than silently
	// writing a null expression.
	NSMutableDictionary<NSNumber *, NSString *> *expressions = [NSMutableDictionary dictionary];
	NSMutableSet<NSNumber *> *toResolve = [NSMutableSet set];
	for (RptqQueryField *output in outputs) {
		[toResolve addObject: @(output.identifier)];
	}
	for (RptqQueryLinks *link in queryObject.hasQueryLinks) {
		if (link.hasLeftField != nil) [toResolve addObject: @(link.hasLeftField.identifier)];
		if (link.hasRightField != nil) [toResolve addObject: @(link.hasRightField.identifier)];
	}
	for (RptqQueryPredicate *predicate in queryObject.hasQueryPredicate) {
		if (predicate.hasLeftField != nil) [toResolve addObject: @(predicate.hasLeftField.identifier)];
		if (predicate.hasRightField != nil) [toResolve addObject: @(predicate.hasRightField.identifier)];
	}
	for (NSNumber *identifier in toResolve) {
		RptqQueryField *field = (RptqQueryField *)[managedObjectContext objectForEntity: NSStringFromClass([RptqQueryField class]) identifier: identifier.longLongValue];
		if (field == nil) continue;
		NSError *fieldError = nil;
		NSString *reference = [self.composingResolver columnReferenceForField: field error: &fieldError];
		if (reference == nil) {
			if (error != NULL) *error = fieldError;
			return @"";
		}
		expressions[identifier] = reference;
	}
	self.composingFieldExpressions = expressions;

	NSMutableString *result = [NSMutableString stringWithString: [database selectPartWithLimitedResults: self.limitResults]];
	NSMutableArray<NSString *> *fieldKeys = [NSMutableArray arrayWithCapacity: outputs.count];
	NSMutableDictionary<NSString *, RptqDatabaseSchemaField *> *fields = [NSMutableDictionary dictionaryWithCapacity: outputs.count];
	for (NSUInteger i = 0; i < outputs.count; i++) {
		RptqQueryField *output = outputs[i];
		NSString *reference = expressions[@(output.identifier)];
		if (i != 0) [result appendString: @",\n"];
		[result appendString: @"\t"];
		[result appendString: reference];
		[fieldKeys addObject: output.outputKey];
		fields[output.outputKey] = output.databaseSchemaField;
	}
	self.fieldKeys = fieldKeys;
	self.fields = fields;
	[result appendString: MADSqlTextFromPart];

	// FROM/JOIN: the shared table-reference walk, resolving composing tables and
	// link fields through the resolver and the pre-resolved expressions.
	MTGraph *graph = [[MTGraph alloc] init];
	for (RptqQueryTable *table in queryObject.hasQueryTables) {
		[graph addVertexWithObject: @(table.identifier)];
	}
	for (RptqQueryLinks *queryLink in queryObject.hasQueryLinks) {
		MTVertex *origin = [graph vertexForObject: @(queryLink.hasLeftField.inQueryTable.identifier)];
		MTVertex *destination = [graph vertexForObject: @(queryLink.hasRightField.inQueryTable.identifier)];
		[graph addEdgeWithOrigin: origin destination: destination object: @(queryLink.identifier) andWeight: @1];
	}

	BOOL isDirectedAcyclicGraph = NO;
	NSError *sortError = NULL;
	MTLinkedList *topologicalSort = [graph topologicalSortWithError: &sortError isDirectedAcyclicGraph: &isDirectedAcyclicGraph];
	if (sortError != nil || !isDirectedAcyclicGraph) {
		if (error != NULL) *error = sortError;
		return @"";
	}

	NSArray *topologicalSortArray = [topologicalSort toArray];
	NSMutableArray<MTVertex *> *vertexArray = [NSMutableArray arrayWithCapacity: topologicalSortArray.count];
	for (MTPair *pair in topologicalSortArray) {
		MTVertex *vertexTable = pair.former;
		if (vertexTable) {
			vertexTable.properties.algorithmColor = MTColorWhite;
			[vertexArray addObject: vertexTable];
		}
	}
	NSNumber *linkDepth = @0;
	NSString *tableReference = [self sqlTableReferenceWithTables: vertexArray
													   linkDepth: &linkDepth
										 forManagedObjectContext: managedObjectContext];
	[result appendString: tableReference];

	MADQueryPredicate *predicate = [[MADQueryPredicate alloc] initWithQueryPredicates: queryObject.hasQueryPredicate
																		fieldResolver: ^NSString *(RptqQueryField *field) {
		return expressions[@(field.identifier)];
	} andDatabase: database];
	[result appendString: predicate.sql];
	[result appendString: [database sqlLimitClause: _limitResults]];
	return result;
}

- (NSString *)sqlTableReferenceWithTables:(NSArray <MTVertex *> *)tables
								linkDepth:(NSNumber * __autoreleasing *)linkDepth
				  forManagedObjectContext:(RptqStoreContext *)managedObjectContext {
	
	NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
	
	NSInteger tableCounter = 0;
	MADDatabase *database = self.database ?: [self.dataDelegate database];
	
	for (MTVertex *vertexTable in tables) {
		if (vertexTable) {
			
			int64_t objectID = [vertexTable.object longLongValue];
			RptqQueryTable *table = [RptqQueryTable queryTableWithObjectID:objectID
													  managedObjectContext:managedObjectContext];
			
			if (vertexTable.properties.algorithmColor == MTColorWhite ||
				vertexTable.properties.algorithmColor == MTColorGray) {
				
				NSArray <MTEdge *> *incidentEdges = vertexTable.incidentEdges;
				
				if (tableCounter > 0) {
					if ((*linkDepth).integerValue == 0){
						[result appendString:@","];
					}
					[result appendString:@"\n\t"];
				}
				
				if (vertexTable.properties.algorithmColor == MTColorWhite) {
					
					if (result.length <= 0) {
						[result appendString:@"\t"];
					}
					
					// A composing table resolves to its attached child; a leaf table to
					// its remote schema table under its query alias.
					if (self.composingResolver != nil && table.upstreamQuery != nil) {
						[result appendString: [self.composingResolver tableReferenceForQueryTable: table]];
					} else {
						NSString *ogTableName = table.databaseSchemaTable.name;
						MADSafeQueryField *safeOgTableName = [database newSafeIdentifier:ogTableName];
						[result appendString:safeOgTableName];

						NSString *tableConnector = [database tableAliasConnector];
						[result appendString:tableConnector];

						NSString *tableName = [table queryAlias];
						MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
						[result appendString:safeTableName];
					}
				}
				
				vertexTable.properties.algorithmColor = MTColorBlack;
				
				for (MTEdge *edge in incidentEdges) {
					MTVertex *vertexTableDestination = edge.destination;
					if (vertexTableDestination &&
						vertexTableDestination.properties.algorithmColor == MTColorWhite) {
						
						
						vertexTableDestination.properties.algorithmColor = MTColorGray;
						
						int64_t queryLinkID = [edge.object longLongValue];
						RptqQueryLinks *queryLink = (RptqQueryLinks *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryLinks class]) identifier:queryLinkID];
						
						
						if (queryLink) {
							NSString *NewLineTab = @"\n\t";
							NSString *Tab = @"\t";
							
							[result appendString:NewLineTab];
							for (NSInteger i = 0; i <= (*linkDepth).integerValue; i++) {
								[result appendString:Tab];
							}
							
							NSString *sqlForLink = [RptqQueryLinks SqlForLinkType:queryLink.type];
							[result appendFormat:@" %@ ", sqlForLink];
							
							RptqQueryField *rightField = queryLink.hasRightField;
							RptqQueryTable *rightTable = rightField.inQueryTable;
							
							if (self.composingResolver != nil && rightTable.upstreamQuery != nil) {
								[result appendString: [self.composingResolver tableReferenceForQueryTable: rightTable]];
							} else {
								NSString *databaseSchemaTable = rightTable.databaseSchemaTable.name;
								MADSafeQueryField *safeDatabaseSchemaTable = [database newSafeIdentifier:databaseSchemaTable];
								[result appendString:safeDatabaseSchemaTable];

								NSString *tableAliasConnector = [database tableAliasConnector];
								[result appendString:tableAliasConnector];

								NSString *ogRightTable = [rightTable queryAlias];
								MADSafeQueryField *safeOgRightTable = [database newSafeIdentifier:ogRightTable];
								[result appendString:safeOgRightTable];
							}
							[result appendString:NewLineTab];
							
							for (NSInteger i = 0; i <= (*linkDepth).integerValue + 1; i++) {
								[result appendString:Tab];
							}
							
							[result appendString:@"ON "];

							RptqQueryField *leftField = queryLink.hasLeftField;

							if (self.composingResolver != nil) {
								[result appendString: self.composingFieldExpressions[@(leftField.identifier)]];
							} else {
								NSString *lft = [leftField.inQueryTable queryAlias];
								MADSafeQueryField *safeField = [database queryKey: leftField.databaseSchemaField.name table: lft];
								[result appendString: safeField];
							}
							[result appendString:@" = "];

							if (self.composingResolver != nil) {
								[result appendString: self.composingFieldExpressions[@(rightField.identifier)]];
							} else {
								NSString *rft = [rightField.inQueryTable queryAlias];
								MADSafeQueryField *safeField = [database queryKey: rightField.databaseSchemaField.name table: rft];
								[result appendString: safeField];
							}
						}
					}
				}
				
				// MARK: Destination vertices.
				NSMutableArray <MTVertex *> *destination;
				destination = [[NSMutableArray alloc] initWithCapacity:vertexTable.numberOfIncidentEdges];
				NSArray *edges = vertexTable.incidentEdges;
				for (MTEdge *edge in edges) {
					MTVertex *vertexTableDestination = edge.destination;
					[destination addObject:vertexTableDestination];
				}
				
				*linkDepth = [[NSNumber alloc] initWithInteger:(*linkDepth).integerValue + 1];
				
				NSString *tableFactor = [self sqlTableReferenceWithTables: destination
																linkDepth: linkDepth
												  forManagedObjectContext: managedObjectContext];
				if (tableFactor.length > 0) {
					
					NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
					
					[result setString: [result stringByTrimmingCharactersInSet:charSet]];
					
					for (NSUInteger i = 0; i < (*linkDepth).unsignedIntegerValue; i++) {
						[result appendFormat:@"\t"];
					}
					[result appendString:tableFactor];
					
					// FIXME: I would think to group these in parentheses, but some databases don't like that.
					//          Maybe make this optional based on DB type.
					//    [result insertString:@"\t(" atIndex:0];
					//    [result appendString:@")\n\t"];
					[result insertString:@"\t" atIndex:0];
					[result appendString:@"\n\t"];
					
				}
				
				*linkDepth = [[NSNumber alloc] initWithInteger:(*linkDepth).integerValue - 1];
				
				tableCounter++;
			}
		}
	}
	return result;
}

#pragma mark -
#pragma mark NSNotification

- (void)handleManagedObjectContextDidChange:(NSNotification *)notification {
	
	BOOL queryChanged = NO;
	
	BOOL (^queryObjectInSet)(NSSet <RptqStoreContext *> *) = ^(NSSet <RptqStoreContext *> *changes){
		for (id change in changes) {
			if (isKindOfRptqQuery(change)) {
				return YES;
			}
		}
		return NO;
	};

	NSSet *changes;
	changes = notification.userInfo[RptqStoreContextUpdatedObjectsKey];
	queryChanged = queryObjectInSet(changes);
	if (!queryChanged) {
		changes = notification.userInfo[RptqStoreContextDeletedObjectsKey];
		queryChanged = queryObjectInSet(changes);
	}
	if (!queryChanged) {
		changes = notification.userInfo[RptqStoreContextInsertedObjectsKey];
		queryChanged = queryObjectInSet(changes);
	}
	if (queryChanged) {
		
	}
}

- (MADQueryType)type { return MADQueryTypeFull; }

@end
