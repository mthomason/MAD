//
//  RptqDatabaseCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabaseCredentals+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDatabase+Extras.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MADDatabaseConnection.h"
#import "MADDatabaseType.h"

#import "RptqDataHelper.h"

@implementation RptqDatabaseCredentals (Extras)

+ (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDatabaseCredentals"];
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
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

- (NSString *)copyDatabaseSchemaName {
    NSString *result = @"";
    MADDatabaseType databaseType = [self.inDatabase databaseType];
    switch (databaseType) {
        
        case MADDatabaseTypeMySQL:
        case MADDatabaseTypeSqlite3:
            result = self.mysql_database.copy;
            break;
        
        case MADDatabaseTypeTDS:
            result = self.tds_database.copy;
            break;

        case MADDatabaseTypeUnknown: {
            
            if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL]]) {
                result = self.mysql_database.copy;
                
                NSNumber *type = [[NSNumber alloc] initWithShort:MADDatabaseTypeMySQL];
                self.inDatabase.databaseDriverTypeEnum = type;
                
            } else if ([self.database_driver_type isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeTDS]]) {
                result = self.tds_database.copy;
                
                NSNumber *type = [[NSNumber alloc] initWithShort:MADDatabaseTypeTDS];
                self.inDatabase.databaseDriverTypeEnum = type;
                
            } else if ([self.database_driver_type isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeSqlite3]]) {
                result = self.mysql_database.copy;
                
                NSNumber *type = [[NSNumber alloc] initWithShort:MADDatabaseTypeSqlite3];
                self.inDatabase.databaseDriverTypeEnum = type;
                
            }
            
            break;
        }
        default:
            result = @"unknown";
            break;
    }
    NSString *resultNoPathExtension = result.stringByDeletingPathExtension;
    NSString *capitalized = resultNoPathExtension.capitalizedString;
    return capitalized;
}

#pragma mark - Static

+ (instancetype)newUserCredentalForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSString *entityName = NSStringFromClass([self class]);
    NSEntityDescription *ed = [NSEntityDescription entityForName:entityName inManagedObjectContext: objectContext];
    id userCredentals = [[self alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
    return userCredentals;
}

+ (NSArray <RptqDatabaseCredentals *> *)newArrayOfUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([RptqDatabaseCredentals class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"database_driver_type" ascending:YES];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    NSError *error = nil;
    NSArray *fetchResults = [objectContext executeFetchRequest:request error:&error];
    NSArray <RptqDatabaseCredentals *> *results;
    results = [[NSArray <RptqDatabaseCredentals *> alloc] initWithArray:fetchResults];
    return results;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********   RptqDatabaseCredentals  *********\n"];
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
    [description appendFormat:@"*********   RptqDatabaseCredentals  *********"];
    return description;
}

@end
