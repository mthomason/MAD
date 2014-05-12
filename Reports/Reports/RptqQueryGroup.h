//
//  RptqQueryGroup.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentSection, RptqQuery, RptqQueryField;

@interface RptqQueryGroup : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * sort;
@property (nonatomic, strong) NSNumber * weight;
@property (nonatomic, strong) RptqQueryField *hasField;
@property (nonatomic, strong) NSSet *hasSection;
@property (nonatomic, strong) RptqQuery *inQuery;
@end

@interface RptqQueryGroup (CoreDataGeneratedAccessors)

- (void)addHasSectionObject:(RptqDocumentSection *)value;
- (void)removeHasSectionObject:(RptqDocumentSection *)value;
- (void)addHasSection:(NSSet *)values;
- (void)removeHasSection:(NSSet *)values;

@end
