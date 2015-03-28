//
//  RptqUserCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqUserCredentals+Extras.h"
#import "RptqDatabase+Extras.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"

@implementation RptqUserCredentals (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqUserCredentals class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqUserCredentals *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

- (NSString *)databaseSchemaName {
    NSString *result = @"";
    MNSDatabaseType databaseType = [[[self inDatabase] databaseDriverTypeEnum] integerValue];
    switch (databaseType) {
        
        case MNSDatabaseTypeMySQL:
        case MNSDatabaseTypeSqlite3:
            result = [self mysql_database];
            break;
        
        case MNSDatabaseTypeMicrosoftSqlServer:
            result = [self tds_database];
            break;

        case MNSDatabaseTypeUnknown: {
            
            if ([[self database_driver_type] isEqualToString:[MTDatabaseMySql identifier]]) {
                result = [self mysql_database];
                [[self inDatabase] setDatabaseDriverTypeEnum:@(MNSDatabaseTypeMySQL)];
                
            } else if ([[self database_driver_type] isEqualToString:[MTDatabaseSqlServer identifier]]) {
                result = [self tds_database];
                [[self inDatabase] setDatabaseDriverTypeEnum:@(MNSDatabaseTypeMicrosoftSqlServer)];
                
            } else if ([[self database_driver_type] isEqualToString:[MTDatabaseSqlite3 identifier]]) {
                result = [self mysql_database];
                [[self inDatabase] setDatabaseDriverTypeEnum:@(MNSDatabaseTypeSqlite3)];
            }
            
            break;
        }
        default:
            result = @"unknown";
            break;
    }
    return [[result stringByDeletingPathExtension] capitalizedString];
}

#pragma mark - Static

+ (instancetype)userCredentalsFactory:(NSManagedObjectContext *)objectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName:NSStringFromClass([RptqUserCredentals class]) inManagedObjectContext: objectContext];
    RptqUserCredentals *userCredentals = [[RptqUserCredentals alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
    return userCredentals;
}

+ (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqUserCredentals class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"database_driver_type" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error = nil;
    NSArray *fetchResults = [objectContext executeFetchRequest:request error:&error];
    NSArray *results = [[NSArray alloc] initWithArray:fetchResults];
    return results;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqUserCredentals *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end