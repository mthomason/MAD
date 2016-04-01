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
#import "MTDatabaseConnection.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

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
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
    self.identifier = identifierObj;
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
    MNSDatabaseType databaseType = [self.inDatabase databaseType];
    switch (databaseType) {
        
        case MNSDatabaseTypeMySQL:
        case MNSDatabaseTypeSqlite3:
            result = [self mysql_database];
            break;
        
        case MNSDatabaseTypeMicrosoftSqlServer:
            result = [self tds_database];
            break;

        case MNSDatabaseTypeUnknown: {
            
            if ([[self database_driver_type] isEqualToString:MADIdentifierDatabaseMySQL]) {
                result = self.mysql_database;
                self.inDatabase.databaseDriverTypeEnum = @(MNSDatabaseTypeMySQL);
                
            } else if ([self.database_driver_type isEqualToString:MADIdentifierDatabaseTDS]) {
                result = self.tds_database;
                [self.inDatabase setDatabaseDriverTypeEnum:@(MNSDatabaseTypeMicrosoftSqlServer)];
                
            } else if ([[self database_driver_type] isEqualToString:MADIdentifierDatabaseSqlite3]) {
                result = [self mysql_database];
                [self.inDatabase setDatabaseDriverTypeEnum:@(MNSDatabaseTypeSqlite3)];
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

+ (instancetype)newUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext NS_RETURNS_RETAINED {
    NSString *entityName = NSStringFromClass([self class]);
    NSEntityDescription *ed = [NSEntityDescription entityForName:entityName inManagedObjectContext: objectContext];
    id userCredentals = [[self alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
    return userCredentals;
}

+ (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext NS_RETURNS_RETAINED {
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

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********   RptqUserCredentals  *********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Type:                   %@\n", self.database_driver_type];
    [description appendFormat:@"MySQL host:             %@\n", self.mysql_host];
    [description appendFormat:@"MySQL database:         %@\n", self.mysql_database];
    [description appendFormat:@"MySQL Port:             %@\n", self.mysql_port];

    [description appendFormat:@"TDS host:               %@\n", self.tds_host];
    [description appendFormat:@"TDS database:           %@\n", self.tds_database];
    [description appendFormat:@"TDS port:               %@\n", self.tds_port];
    
    [description appendFormat:@"SF Login Domain:        %@\n", self.sf_login_domain];
    [description appendFormat:@"SF Login Identifier:    %@\n", self.sf_login_identifier];
    [description appendFormat:@"SF Login Key:           %@\n", self.sf_login_key];
    [description appendFormat:@"SF Login Redirect URL:  %@\n", self.sf_login_redirect_uri];
    [description appendFormat:@"*********   RptqUserCredentals  *********"];
    return description;
}

@end
