//
//  Table.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Database, Field;

@interface Table : NSManagedObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * label_plural;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * queryable;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) Database *inDatabase;
@end

@interface Table (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(Field *)value;
- (void)removeHasFieldsObject:(Field *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

@end
