//
//  MTQueryReport.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryFull.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSManagedObjectID.h>

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

#import "MTDatabase.h"
#import "MADDatabaseField.h"
#import "MADQueryPredicate.h"
#import "MADQueryLimitClause.h"

#import "RptqQuerySort.h"

#import "MADQueryActiveQueryFields.h"
#import "MADQuerySelectExpression.h"
#import "MADQuerySelectExpressionAllFields.h"
#import "MADQuerySelectExpressionActiveFields.h"


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

@interface MTQueryFull ()

    @property (nonatomic, copy) NSManagedObjectID *objectID;

@end

@implementation MTQueryFull

- (void)dealloc {
    self.dataDelegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithQuery: (RptqQuery *)query
                andQueryLimit: (NSUInteger)queryLimit {
    if (self = [super initWithObject:query]) {
        _objectID = query.objectID.copy;
        _limitResults = queryLimit;
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self
                          selector: @selector(handleManagedObjectContextDidChange:)
                              name: NSManagedObjectContextObjectsDidChangeNotification
                            object: query.managedObjectContext];
    }
    return self;
}

- (instancetype)initWithObject:(NSDictionary *)object {
    
    NSAssert([object isKindOfClass:[NSDictionary class]],
             @"MTQueryFull expects NSDictionary with parameters.");

    NSNumber *parameterScheam = [[NSNumber alloc] initWithShort: MTQueryCacheFullQuerySchema];
    NSNumber *queryLimitWrapper = object[@"MADQueryLimit"];
    NSUInteger queryLimit = queryLimitWrapper.unsignedIntegerValue;
    RptqQuery *query = object[parameterScheam];
    id result = [self initWithQuery:query andQueryLimit:queryLimit];
    return result;
}

- (NSString *)copySQLWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                        error:(NSError * __autoreleasing *)error {
    [super getSqlWithError:error];
    NSString *activeFields;
    activeFields = [self SQLOnlyActiveFields: YES
                        managedObjectContext: managedObjectContext
                                       error: error];
    return activeFields;
}

- (NSString *)SQLOnlyActiveFields: (BOOL)onlyActiveFields
             managedObjectContext: (NSManagedObjectContext *)managedObjectContext
                            error: (NSError * __autoreleasing *)error {
    
    RptqDocument *document;
    document = [RptqDocument newDocumentReadFromManagedObjectContext:managedObjectContext];
    RptqDatabase *databaseSchema = document.hasDatabaseSchemas.anyObject;
    RptqQuery *queryObject = databaseSchema.hasQueries.anyObject;

    
    if (queryObject.hasQueryTables.count <= 0) return @"";
        
    NSMutableString *result = [[NSMutableString alloc] initWithString: @""];
    
    MTDatabase *database = [self.dataDelegate database];
    NSString *selectPart = [database selectPartWithLimitedResults:self.limitResults];


    MADQueryPredicate *predicate;
    MADQueryLimitClause *limitClause;

    predicate = [[MADQueryPredicate alloc] initWithQueryPredicates: queryObject.hasQueryPredicate
                                                       andDatabase: database];
    
    limitClause = [[MADQueryLimitClause alloc] initWithLimit: _limitResults
                                                 andDatabase: database];

    NSString *predicatePart = predicate.sql.copy;
    NSString *limitPart = limitClause.sql.copy;
    
    
    
    [result appendString:selectPart];
    
    //Use a graph to represent the query: verticies are tables and edges are links.

    MTGraph *graph = [[MTGraph alloc] init];
    NSSet *hasTables = queryObject.hasQueryTables;
    
    //Add a vertex to the graph for each table.
    for (RptqDatabaseSchemaTable *table in hasTables) {
        //@autoreleasepool {
            [graph addVertexWithObject: table.objectID];
        //}
    }
    
    //Create an edge in the graph for each query link.
    NSSet *hasQueryLinks = queryObject.hasQueryLinks;
    NSNumber *weight = @1;
    
    MTVertex *origin, *destination;
    for (RptqQueryLinks *queryLink in hasQueryLinks) {
        
        origin =        [graph vertexForObject: queryLink.hasLeftField.inQueryTable.objectID];
        destination =   [graph vertexForObject: queryLink.hasRightField.inQueryTable.objectID];
        
        [graph addEdgeWithOrigin:origin destination:destination
                          object:queryLink.objectID andWeight:weight];
    }
    
    
    // MARK: Sort the vectors topologically.
    BOOL  isDirectedAcyclicGraph;
    NSAssert(graph != nil, @"Where's the graph?");
    
    NSError * __autoreleasing sortError = NULL;
    MTLinkedList *topologicalSort = [graph topologicalSortWithError:&sortError
                                             isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
    
    // MARK: Error on circuts or other bad query.
    if (*error != NULL) {
        NSAssert(YES, @"Error: Bad conditions.");
        [result setString:@""];
    } else {
        
        NSArray *topologicalSortArray = [topologicalSort toArray];
        
        
        MADQuerySelectExpression *select;
        if (onlyActiveFields) {
            select = [[MADQuerySelectExpressionActiveFields alloc] initWithDatabase: database
                                                            forManagedObjectContext: managedObjectContext];
            self.fieldKeys = ((MADQuerySelectExpressionActiveFields *)select).fieldKeys.copy;
            self.fields = ((MADQuerySelectExpressionActiveFields *)select).fields.copy;
        } else {
            // MAKR: List each field in the query.
            NSArray *sort = [topologicalSort toArray];
            select = [[MADQuerySelectExpressionAllFields alloc] initWithDatabase: database
                                                                          tables: sort
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
            NSDictionary *errorInfo;
            errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                            message, NSLocalizedDescriptionKey, nil];
            *error = [NSError errorWithDomain: @"MTQuery"
                                         code: 5774
                                     userInfo: errorInfo];
            [result setString:@""];
        }
        
    }
    
    if (result.length > 0) {
        [result appendString:predicatePart];
        [result appendString:limitPart];
    }
    

    return result;
}

- (NSString *)sqlTableReferenceWithTables:(NSArray <MTVertex *> *)tables
                                linkDepth:(NSNumber * __autoreleasing *)linkDepth
                  forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];

    NSInteger tableCounter = 0;
    MTDatabase *database = [self.dataDelegate database];

    for (MTVertex *vertexTable in tables) {
        if (vertexTable) {
            
            NSManagedObjectID *objectID = vertexTable.object;
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
                    
                    NSString *ogTableName = table.databaseSchemaTable.name;
                    MADSafeQueryField *safeOgTableName = [database newSafeIdentifier:ogTableName];
                    [result appendString:safeOgTableName];
                    
                    NSString *tableConnector = [database tableAliasConnector];
                    [result appendString:tableConnector];
                    
                    NSString *tableName = [table queryAlias];
                    MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
                    [result appendString:safeTableName];
                }
                
                vertexTable.properties.algorithmColor = MTColorBlack;
                
                for (MTEdge *edge in incidentEdges) {
                    MTVertex *vertexTableDestination = edge.destination;
                    if (vertexTableDestination &&
                        vertexTableDestination.properties.algorithmColor == MTColorWhite) {

                        
                        vertexTableDestination.properties.algorithmColor = MTColorGray;
                        
                        NSManagedObjectID *queryLinkID = edge.object;
                        RptqQueryLinks *queryLink = [managedObjectContext objectWithID:queryLinkID];
                        
                        
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
                            
                            NSString *databaseSchemaTable = rightTable.databaseSchemaTable.name;
                            MADSafeQueryField *safeDatabaseSchemaTable = [database newSafeIdentifier:databaseSchemaTable];
                            [result appendString:safeDatabaseSchemaTable];
                            
                            NSString *tableAliasConnector = [database tableAliasConnector];
                            [result appendString:tableAliasConnector];
                            
                            NSString *ogRightTable = [rightTable queryAlias];
                            MADSafeQueryField *safeOgRightTable = [database newSafeIdentifier:ogRightTable];
                            [result appendString:safeOgRightTable];
                            [result appendString:NewLineTab];
                            
                            for (NSInteger i = 0; i <= (*linkDepth).integerValue + 1; i++) {
                                [result appendString:Tab];
                            }
                            
                            [result appendString:@"ON "];
                            
                            RptqQueryField *leftField = queryLink.hasLeftField;
                            
                            NSString *lft = [leftField.inQueryTable queryAlias];
                            MADSafeQueryField *safeField;
                            safeField = [database newSafeQueryField: leftField.databaseSchemaField.name
                                                           andTable: lft];
                            [result appendString: safeField];
                            [result appendString:@" = "];
                            
                            NSString *rft = [rightField.inQueryTable queryAlias];
                            safeField = [database newSafeQueryField: rightField.databaseSchemaField.name
                                                           andTable: rft];
                            [result appendString: safeField];
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
    
    BOOL (^queryObjectInSet)(NSSet <NSManagedObjectContext *> *);
    queryObjectInSet = ^(NSSet <NSManagedObjectContext *> *changes){
        for (id change in changes) {
            if (isKindOfRptqQuery(change)) {
                return YES;
            }
        }
        return NO;
    };
    
    NSSet *changes;
    changes = notification.userInfo[NSUpdatedObjectsKey];
    queryChanged = queryObjectInSet(changes);
    if (!queryChanged) {
        changes = notification.userInfo[NSDeletedObjectsKey];
        queryChanged = queryObjectInSet(changes);
    }
    if (!queryChanged) {
        changes = notification.userInfo[NSInsertedObjectsKey];
        queryChanged = queryObjectInSet(changes);
    }
    if (queryChanged) {
        
    }

}

- (MADQueryType)type {
    return MADQueryTypeFull;
}

@end

