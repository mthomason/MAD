//
//  MNSDocumentReport.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDocumentReport.h"

@interface MNSDocumentReport ()

@end

@implementation MNSDocumentReport

- (void)dealloc {
    [super dealloc];
}



//Create a new file
- (id)initFileWithName:(NSString *)name completion:(void (^)(BOOL success))completion {
    self = [super initFileWithName:name extension:SCHEMA_PATH_EXTENSION
                 managedObjectType:[UIManagedDocumentQuery class] completion:^(BOOL success) {
                     if (self) {
                         RptqDocument *doc = [RptqDocument createMainDocumentForManagedObjectContext: [[self managedDocument] managedObjectContext]];
                         [doc setName: name];
                         [self save:^(BOOL success) {
                             completion(success);
                         }];
                     }
                 }];
    return self;
}

//Open an existing file
- (id)initFileWithUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {
    self = [super initFileWithUrl:url completion:^(BOOL success) {
        if (self) {
            completion(success);
        }
    }];
    return self;
}

- (void)save:(void (^)(BOOL success))completion {
    [super save: ^(BOOL success) {
        completion(success);
    }];
}

- (void)saveToUrl:(NSURL *)url completion:(void (^)(BOOL success))completion {
    [super saveToUrl:url completion:^(BOOL success){
        completion(success);
    }];
}

//Add a new connection to the report
- (void)addDatasourceToReport: (MNSDatabase *)database
                   completion: (void (^)(BOOL success))completion {
    
    NSManagedObjectContext *managedObjectContext = [[self managedDocument] managedObjectContext];
    
    RptqDocument *rptqDocument = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];


    NSNumber *connectionId = @([[rptqDocument hasDatabaseSchemas] count] + 1);

    RptqDatabase *rptqDatabase = [RptqDatabase createNewDatabaseForManagedObjectContext: managedObjectContext
                                                                             driverType: KEY_DB_TYPE_SF
                                                                           connectionId: connectionId];
    
    [rptqDatabase setOwnedByUser: [RptqUserCredentals createNewUserCredentalsForManagedObjectContext:managedObjectContext]];
    
    [rptqDocument setHasDatabaseSchemas: [[rptqDocument hasDatabaseSchemas] setByAddingObject: rptqDatabase]];
    
    [database getTables:^(NSArray *tables) {
        
        [tables enumerateObjectsUsingBlock: ^(MNSDatabaseTable *obj, NSUInteger idx, BOOL *stop) {
            
            RptqTable *rptqTable = [RptqTable createNewTableForManagedObjectContext: managedObjectContext
                                                                           andTable: obj];
            
            RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                 withConnecitonId: connectionId];
            
            if (currentDatabase) [currentDatabase addHasTablesObject: rptqTable];
            
            [database getFieldsForTable:rptqTable completion:^(NSArray *fields) {
                
                [fields enumerateObjectsUsingBlock:^(MNSDatabaseField *objField, NSUInteger idx, BOOL *stop) {
                    
                    RptqDatabase *currentDatabase = [RptqDatabase getDatabaseFromDocument: rptqDocument
                                                                         withConnecitonId: connectionId];

                    RptqTable *rptqTableOrigional = [RptqTable getTableForManagedObjectContext: managedObjectContext
                                                                                      database: currentDatabase
                                                                                  andTableName: [obj name]];
                    
                    [rptqTableOrigional addHasFieldsObject: [RptqField createNewFieldForManagedObjectContext: managedObjectContext
                                                                                                    andField: objField]];
                }];
                
            }];
            
            [rptqTable release];
        }];
        
        completion(YES);
        
    }];
    
}


- (void)refresh {
    [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)sendTo {
    [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

@end