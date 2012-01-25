//
//  RptqQuery.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqQueryPredicate, RptqQuerySort, RptqQueryTables;

@interface RptqQuery : NSManagedObject

@property (nonatomic, retain) NSNumber * override;
@property (nonatomic, retain) NSString * overrideText;
@property (nonatomic, retain) RptqDocument *inQueryBuilderDocument;
@property (nonatomic, retain) NSSet *hasQueryTables;
@property (nonatomic, retain) RptqQuerySort *hasQuerySort;
@property (nonatomic, retain) RptqQueryPredicate *hasQueryPredicate;
@end

@interface RptqQuery (CoreDataGeneratedAccessors)

- (void)addHasQueryTablesObject:(RptqQueryTables *)value;
- (void)removeHasQueryTablesObject:(RptqQueryTables *)value;
- (void)addHasQueryTables:(NSSet *)values;
- (void)removeHasQueryTables:(NSSet *)values;

@end
