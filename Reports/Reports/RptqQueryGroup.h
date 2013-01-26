//
//  RptqQueryGroup.h
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentSection, RptqField, RptqQuery;

@interface RptqQueryGroup : NSManagedObject

@property (nonatomic, retain) NSString * field;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * sort;
@property (nonatomic, retain) NSString * table;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) RptqField *hasField;
@property (nonatomic, retain) NSSet *hasSection;
@property (nonatomic, retain) RptqQuery *inQuery;
@end

@interface RptqQueryGroup (CoreDataGeneratedAccessors)

- (void)addHasSectionObject:(RptqDocumentSection *)value;
- (void)removeHasSectionObject:(RptqDocumentSection *)value;
- (void)addHasSection:(NSSet *)values;
- (void)removeHasSection:(NSSet *)values;

@end
