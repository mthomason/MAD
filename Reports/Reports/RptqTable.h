//
//  RptqTable.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabase, RptqField, RptqQuery;

@interface RptqTable : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * label_plural;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * queryable;
@property (nonatomic, retain) NSNumber * designerOriginX;
@property (nonatomic, retain) NSNumber * designerOriginY;
@property (nonatomic, retain) NSNumber * designerSizeWidth;
@property (nonatomic, retain) NSNumber * designerSizeHeight;
@property (nonatomic, retain) NSNumber * designerInitalLayout;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) RptqDatabase *inDatabase;
@property (nonatomic, retain) NSSet *inQuery;
@end

@interface RptqTable (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(RptqField *)value;
- (void)removeHasFieldsObject:(RptqField *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

- (void)addInQueryObject:(RptqQuery *)value;
- (void)removeInQueryObject:(RptqQuery *)value;
- (void)addInQuery:(NSSet *)values;
- (void)removeInQuery:(NSSet *)values;

@end
