//
//  RptqUserCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqUserCredentals+Extras.h"

@implementation RptqUserCredentals (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (RptqUserCredentals *)createNewUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName:NSStringFromClass([RptqUserCredentals class]) inManagedObjectContext: objectContext];
    RptqUserCredentals *userCredentals = [[RptqUserCredentals alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
    return [userCredentals autorelease];
}

+ (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqUserCredentals class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"database_driver_type" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    NSError *error = nil;
    NSArray *results = [[NSArray alloc] initWithArray:[objectContext executeFetchRequest:request error:&error]];
    if (error) [error presentErrorToUser];
    return results;
}

@end