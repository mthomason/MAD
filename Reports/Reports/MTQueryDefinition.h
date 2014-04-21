//
//  MTQueryDefinition.h
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTQueryDefinitionSort, MTQueryDefinitionGroup, MTQueryDefinitionLinks,
        MTQueryDefinitionPredicate, MTQueryDefinitionTable;

@interface MTQueryDefinition : NSObject

@property (nonatomic, retain) NSString * cachedText;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) NSSet *hasQueryGroups;
@property (nonatomic, retain) NSSet *hasQueryLinks;
@property (nonatomic, retain) NSSet *hasQueryPredicate;
@property (nonatomic, retain) MTQueryDefinitionSort *hasQuerySort;
@property (nonatomic, retain) NSSet *hasQueryTables;

//- (void)addHasFieldsObject:(RptqDatabaseSchemaField *)value;
//- (void)removeHasFieldsObject:(RptqDatabaseSchemaField *)value;
//- (void)addHasFields:(NSSet *)values;
//- (void)removeHasFields:(NSSet *)values;

- (void)addHasQueryGroupsObject:(MTQueryDefinitionGroup *)value;
- (void)removeHasQueryGroupsObject:(MTQueryDefinitionGroup *)value;
- (void)addHasQueryGroups:(NSSet *)values;
- (void)removeHasQueryGroups:(NSSet *)values;

- (void)addHasQueryLinksObject:(MTQueryDefinitionLinks *)value;
- (void)removeHasQueryLinksObject:(MTQueryDefinitionLinks *)value;
- (void)addHasQueryLinks:(NSSet *)values;
- (void)removeHasQueryLinks:(NSSet *)values;

- (void)addHasQueryPredicateObject:(MTQueryDefinitionPredicate *)value;
- (void)removeHasQueryPredicateObject:(MTQueryDefinitionPredicate *)value;
- (void)addHasQueryPredicate:(NSSet *)values;
- (void)removeHasQueryPredicate:(NSSet *)values;

- (void)addHasQueryTablesObject:(MTQueryDefinitionTable *)value;
- (void)removeHasQueryTablesObject:(MTQueryDefinitionTable *)value;
- (void)addHasQueryTables:(NSSet *)values;
- (void)removeHasQueryTables:(NSSet *)values;

@end
