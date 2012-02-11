//
//  RptqQuery.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTables;

@interface RptqQuery : NSManagedObject

@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) NSSet *hasQueryGroups;
@property (nonatomic, retain) NSSet *hasQueryLinks;
@property (nonatomic, retain) NSSet *hasQueryPredicate;
@property (nonatomic, retain) RptqQuerySort *hasQuerySort;
@property (nonatomic, retain) NSSet *hasQueryTables;
@property (nonatomic, retain) RptqDocument *inQueryBuilderDocument;
@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasQueryGroupsObject:(RptqQueryGroup *)value;
- (void)removeHasQueryGroupsObject:(RptqQueryGroup *)value;
- (void)addHasQueryGroups:(NSSet *)values;
- (void)removeHasQueryGroups:(NSSet *)values;

- (void)addHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)removeHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)addHasQueryLinks:(NSSet *)values;
- (void)removeHasQueryLinks:(NSSet *)values;

- (void)addHasQueryPredicateObject:(RptqQueryPredicate *)value;
- (void)removeHasQueryPredicateObject:(RptqQueryPredicate *)value;
- (void)addHasQueryPredicate:(NSSet *)values;
- (void)removeHasQueryPredicate:(NSSet *)values;

- (void)addHasQueryTablesObject:(RptqQueryTables *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTables *)value;
- (void)addHasQueryTables:(NSSet *)values;
- (void)removeHasQueryTables:(NSSet *)values;

@end
