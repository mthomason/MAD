//
//  Relationship.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Database, Field;

@interface Relationship : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *hasFields;
@property (nonatomic, retain) Database *inDatabase;
@end

@interface Relationship (CoreDataGeneratedAccessors)

- (void)addHasFieldsObject:(Field *)value;
- (void)removeHasFieldsObject:(Field *)value;
- (void)addHasFields:(NSSet *)values;
- (void)removeHasFields:(NSSet *)values;

@end
