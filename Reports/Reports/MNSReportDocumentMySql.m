//
//  NSDatabaseMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSReportDocumentMySql.h"
#import <stdio.h>
#import "Constants.h"

typedef void (^rsltBlk_fldNames)(MNSReportDocumentMySql *database, RptqTable *originTable, NSArray *fields);
typedef void (^rsltBlk_results)(MNSReportDocumentMySql *database, NSArray *results);
typedef void (^rsltBlk_complete)(MNSReportDocumentMySql *database, BOOL complete);

@interface MNSReportDocumentMySql()

@property (copy) NSString *username;
@property (copy) NSString *password;
@property (copy) NSString *host;
@property (assign) NSInteger port;

@property (copy) rsltBlk_complete resultBlockComplete;

- (void)resetDataWithCompletionHandler:(void (^)(MNSReportDocumentMySql *database, BOOL complete))completion;

@end

@implementation MNSReportDocumentMySql

- (void)dealloc {
    [_username release];
    [_password release];
    [_host release];
    [super dealloc];
}

//Init with new file name. Create and open the file at that url.
//  Fill that file with the table names and fields names from this database.
- (id)initNewFileWithName: (NSString *)name completion: (void (^)(BOOL success))completion {
    self = [super initNewFileWithName: name completion: ^(BOOL success) {
        if (self) {
            [self setSchemaName: name];
            switch ([[self managedDocumentQuery] documentState]) {
                case UIDocumentStateNormal: {
                    [self login: ^(MNSReportDocumentMySql *database, BOOL complete) {
                        if (complete) {
                            [self resetDataWithCompletionHandler:^(MNSReportDocumentMySql *database, BOOL complete) {
                                completion(YES);
                            }];
                        } else {
                            completion(NO);
                        }
                    }];
                    break;
                }
                default:
                    break;
            }
        }
    }];
    return self;
}

- (void)login:(void (^)(MNSReportDocumentMySql *database, BOOL complete))completion {
    //kickoff authentication
    self.resultBlockComplete = completion;
    //NSLog(@"self->resultBlockLoginComplete: %@", resultBlockLoginComplete);
    
#warning Login to database to fetch schema???
    
    self.resultBlockComplete(self, YES);

}


- (void)resetDataWithCompletionHandler:(void (^)(MNSReportDocumentMySql *database, BOOL complete))completion {
/*
    //Fetch the existing object model.
    NSManagedObjectContext *moc = [[[self managedDocumentQuery] managedObjectContext] retain];
    
    RptqDocument *doc = [[RptqDocument createMainDocumentForManagedObjectContext: moc] retain];
    [doc setName: [self schemaName]];
    [[[doc hasDatabaseSchema] ownedByUser] setDatabase_driver_type: KEY_DB_TYPE_SF];
    [[doc hasDatabaseSchema] setDatabase_driver_type: KEY_DB_TYPE_SF];
    
    [self tablesInDataseAsyc: nil completion: ^(MNSReportDocumentSalesForce *database, NSArray *tables) {
        
        [tables enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *tableDictionary = [obj retain];
            NSEntityDescription *tableEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqTable class])
                                                           inManagedObjectContext: moc];
            
            RptqTable *rptqTable = [[RptqTable alloc] initWithEntity:tableEntity insertIntoManagedObjectContext:moc];
            [rptqTable setName: [tableDictionary objectForKey: @"name"]];
            [rptqTable setLabel: [tableDictionary objectForKey: @"label"]];
            [rptqTable setQueryable: [NSNumber numberWithBool: [[tableDictionary objectForKey: @"queryable"] boolValue]]];
            [rptqTable setLabel_plural: [tableDictionary objectForKey: @"labelPlural"]];
            [tableDictionary release];
            
            [[doc hasDatabaseSchema] addHasTablesObject: rptqTable];
            
            [database fieldsInDatabase:nil andTable:rptqTable completion:^(MNSReportDocumentSalesForce *database, RptqTable *originTable, NSArray *fields) {
                
                [fields retain];
                [fields enumerateObjectsUsingBlock:^(id objField, NSUInteger idx, BOOL *stop) {
                    
                    NSDictionary *fieldDictionary = [objField retain];
                    
                    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqField class]) inManagedObjectContext: moc];
                    RptqField *rptqField = [[RptqField alloc] initWithEntity: fieldEntity insertIntoManagedObjectContext: moc];
                    [rptqField setLabel: [fieldDictionary objectForKey:@"label"]];
                    [rptqField setName: [fieldDictionary objectForKey:@"name"]];
                    [rptqField setDatatype: [fieldDictionary objectForKey:@"type"]];
                    [fieldDictionary release];
                    
                    if (originTable) [originTable addHasFieldsObject: rptqField];
                    
                    [rptqField release];
                }];
                [fields release];
                
            }];
            
            [rptqTable release];
        }];
        
        [self save];
        completion(database, YES);
        
    }];
    [moc release];
 */
}


- (id)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username andPassword:(NSString *)password {
    self = [super init];
    if (self) {
        [self setUsername: username];
        [self setPassword: password];
        [self setHost: host];
        [self setPort: port];
    }
    return self;
}

- (id)initWithOptions:(NSDictionary *)optons {
    self = [super init];
    if (self) {

    }
    return self;
}

@end