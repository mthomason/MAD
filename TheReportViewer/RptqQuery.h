//
//  RptqQuery.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTables;

@interface RptqQuery : NSManagedObject

@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) NSSet *hasQueryLinks;
@property (nonatomic, retain) RptqQueryPredicate *hasQueryPredicate;
@property (nonatomic, retain) RptqQuerySort *hasQuerySort;
@property (nonatomic, retain) NSSet *hasQueryTables;
@property (nonatomic, retain) RptqDocument *inQueryBuilderDocument;
@property (nonatomic, retain) NSSet *hasQueryGroups;
@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)removeHasQueryLinksObject:(RptqQueryLinks *)value;
- (void)addHasQueryLinks:(NSSet *)values;
- (void)removeHasQueryLinks:(NSSet *)values;

- (void)addHasQueryTablesObject:(RptqQueryTables *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTables *)value;
- (void)addHasQueryTables:(NSSet *)values;
- (void)removeHasQueryTables:(NSSet *)values;

- (void)addHasQueryGroupsObject:(NSManagedObject *)value;
- (void)removeHasQueryGroupsObject:(NSManagedObject *)value;
- (void)addHasQueryGroups:(NSSet *)values;
- (void)removeHasQueryGroups:(NSSet *)values;

@end
