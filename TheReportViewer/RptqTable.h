//
//  RptqTable.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqField;

@interface RptqTable : NSManagedObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * label_plural;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * queryable;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@end

@interface RptqTable (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqField *)value;
- (void)removeHasFieldsObject:(RptqField *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

@end
