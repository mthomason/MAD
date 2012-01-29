//
//  RptqQuery.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/28/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqQueryPredicate, RptqQuerySort, RptqQueryTables;

@interface RptqQuery : NSManagedObject

@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) RptqQueryPredicate *hasQueryPredicate;
@property (nonatomic, retain) RptqQuerySort *hasQuerySort;
@property (nonatomic, retain) NSSet *hasQueryTables;
@property (nonatomic, retain) RptqDocument *inQueryBuilderDocument;
@property (nonatomic, retain) NSSet *hasQueryLinks;
@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasQueryTablesObject:(RptqQueryTables *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTables *)value;
- (void)addHasQueryTables:(NSSet *)values;
- (void)removeHasQueryTables:(NSSet *)values;

- (void)addHasQueryLinksObject:(NSManagedObject *)value;
- (void)removeHasQueryLinksObject:(NSManagedObject *)value;
- (void)addHasQueryLinks:(NSSet *)values;
- (void)removeHasQueryLinks:(NSSet *)values;

@end
