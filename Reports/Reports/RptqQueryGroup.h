//
//  RptqQueryGroup.h
//  Reports
//
//  Created by Michael Thomason on 6/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentSection, RptqQuery, RptqQueryField;

@interface RptqQueryGroup : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * sort;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) RptqQueryField *hasField;
@property (nonatomic, retain) NSSet *hasSection;
@property (nonatomic, retain) RptqQuery *inQuery;
@end

@interface RptqQueryGroup (CoreDataGeneratedAccessors)

- (void)addHasSectionObject:(RptqDocumentSection *)value;
- (void)removeHasSectionObject:(RptqDocumentSection *)value;
- (void)addHasSection:(NSSet *)values;
- (void)removeHasSection:(NSSet *)values;

@end
