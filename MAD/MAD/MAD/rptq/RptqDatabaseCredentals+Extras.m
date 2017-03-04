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

- (NSString *)databaseSchemaName {
    NSString *result = @"";
    MADDatabaseType databaseType = [self.inDatabase databaseType];
    switch (databaseType) {
        
        case MADDatabaseTypeMySQL:
        case MADDatabaseTypeSqlite3:
            result = self.dbname.copy;
            break;
        
        case MADDatabaseTypeTDS:
            result = self.dbname.copy;
            break;

        case MADDatabaseTypeUnknown: {
            
            if ([self.driverID isEqualToString: [RptqDatabaseCredentals driverIDMySQL]]) {
                result = self.dbname.copy;
                self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
                
            } else if ([self.driverID isEqualToString:[RptqDatabaseCredentals driverIDTDS]]) {
                result = self.dbname.copy;
                self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeTDS;
                
            } else if ([self.driverID isEqualToString:[RptqDatabaseCredentals driverIDSqlite3]]) {
                result = self.dbname.copy;
                self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
                
            }
            
            break;
        }
        default:
            result = @"unknown";
            break;
    }
    return result.stringByDeletingPathExtension.capitalizedString;
}

#pragma mark - Static

+ (instancetype)newDatabaseCredental:(NSManagedObjectContext *)objectContext {
    NSString *entityName = NSStringFromClass([self class]);
    NSEntityDescription *ed = [NSEntityDescription entityForName: entityName
                                          inManagedObjectContext: objectContext];
    id userCredentals = [[self alloc] initWithEntity:ed
                      insertIntoManagedObjectContext:objectContext];
    return userCredentals;
}

+ (NSArray <RptqDatabaseCredentals *> *)newDatabaseCredentals:(NSManagedObjectContext *)context {
    NSFetchRequest *request;
    NSString *dbCredentialsClassName = NSStringFromClass([RptqDatabaseCredentals class]);
    request = [[NSFetchRequest alloc] initWithEntityName:dbCredentialsClassName];
    NSSortDescriptor *sort;
    sort = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(driverID))
                                         ascending: YES];
    NSArray <NSSortDescriptor *> *sortDescriptors = [[NSArray alloc] initWithObjects: sort, nil];
    request.sortDescriptors = sortDescriptors;
    NSError *error = nil;
    NSArray *fetchResults = [context executeFetchRequest:request error:&error];
    NSArray <RptqDatabaseCredentals *> *results;
    results = [[NSArray <RptqDatabaseCredentals *> alloc] initWithArray:fetchResults];
    return results;
}

+ (NSString *)driverIDMySQL {
    return [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL];
}

+ (NSString *)driverIDTDS {
    return [MADDatabaseConnection Identifier:MADDatabaseTypeTDS];
}

+ (NSString *)driverIDSqlite3 {
    return [MADDatabaseConnection Identifier:MADDatabaseTypeSqlite3];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********   RptqDatabaseCredentals  *********\n"];
    [description appendFormat:@"Identifier:             %lld\n",    self.identifier];
    [description appendFormat:@"Type:                   %@\n",      self.driverID];
    [description appendFormat:@"Host:                   %@\n",      self.host];
    [description appendFormat:@"Database:               %@\n",      self.dbname];
    [description appendFormat:@"Port:                   %lld\n",    self.port];
    [description appendFormat:@"*********   RptqDatabaseCredentals  *********"];
    return description;
}

@end
