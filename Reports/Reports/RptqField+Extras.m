//
//  RptqField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqField+Extras.h"

@implementation RptqField (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label name:(NSString *)name
                                         andDatatype:(NSString *)dataType {
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqField class]) inManagedObjectContext: objectContext];
    RptqField *rptqField = [[RptqField alloc] initWithEntity: fieldEntity
                              insertIntoManagedObjectContext: objectContext];
    [rptqField setLabel:    label];
    [rptqField setName:     name];
    [rptqField setDatatype: dataType];
    return [rptqField autorelease];
}

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andField:(MNSDatabaseField *)field {
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqField class]) inManagedObjectContext: objectContext];
    RptqField *rptqField = [[RptqField alloc] initWithEntity: fieldEntity
                              insertIntoManagedObjectContext: objectContext];
    [rptqField setLabel:    [field label]];
    [rptqField setName:     [field name]];
    [rptqField setDatatype: [field datatype]];
    return [rptqField autorelease];
}

/*
+ (void)addFieldToQueryForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
}

+ (void)removeFieldFromQueryInManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
}
*/

@end