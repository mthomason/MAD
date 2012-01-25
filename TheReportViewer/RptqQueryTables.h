//
//  RptqQueryTables.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery, RptqQueryFields;

@interface RptqQueryTables : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) RptqQuery *inQuery;
@property (nonatomic, retain) NSSet *hasFields;
@end

@interface RptqQueryTables (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqQueryFields *)value;
- (void)removeHasFieldsObject:(RptqQueryFields *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

@end
