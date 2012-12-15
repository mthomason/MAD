//
//  RptqField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqField+Extras.h"

@implementation RptqField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqField class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqField *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

#pragma mark - Static

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

- (NSString *)display {
    return [[NSString stringWithFormat:@"%@.%@", [[self inTable] name], [self name]] lowercaseString];
}

/*
+ (void)addFieldToQueryForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
}

+ (void)removeFieldFromQueryInManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
}
*/

// MARK: MTProtocolLog

- (NSString *)humanReadableObjectIdentifier {
    return [NSString stringWithFormat:@"%@.%@", [[self inTable] name], [self name]];
}

- (NSString *)toString {
    return [self humanReadableObjectIdentifier];
}

- (NSString *)toStringForDebugging {
    return [self humanReadableObjectIdentifier];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end