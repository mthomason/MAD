//
//  MADDatabaseOperationTest.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationDatabaseTestConnection.h"

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

#import <MADFoundation/MADDataTableType.h>

#import <MAD/MADDatabaseProtocol.h>
#import <MAD/MADCredential.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTQueryTest.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADErrorUserInfo.h>
#import <MAD/MADDataTable.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>

#import "MADOperationKeyChainGet.h"

#import <os/log.h>

@interface MADOperationDatabaseTestConnection ()
    <MADDatabaseProtocol>

    //Parameters
    @property (nonatomic, copy) MADDatabaseConnection *databaseConnection;
    @property (nonatomic, copy) MADCredential *credentials;

    //Store
    @property (nonatomic, strong) MTDatabase *database;
    @property (nonatomic, strong) MADDataTable *datatable;

    //Results
    @property (nonatomic, readwrite, strong) NSError *error;
    @property (nonatomic, readwrite, assign) BOOL success;

@end

@implementation MADOperationDatabaseTestConnection

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection {
    if (self = [super init]) {
        _databaseConnection = connection.copy;
        _credentials = nil;
        _success = NO;
    }
    return self;
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection
                               credentials:(MADCredential *)credentials {
    if (self = [super init]) {
        _databaseConnection = connection.copy;
        _credentials = credentials.copy;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    // Find credentials from dependencies.
    if (self.credentials == nil) {
        
        NSString *username = nil;
        NSString *password = nil;
        
        NSArray <NSOperation *> *dependencies = self.dependencies;
        for (NSOperation *operation in dependencies) {

            if ([operation conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
 
                if (((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).gotCredentials) {
                    MADCredential *credentials;
                    credentials = ((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).credentials.copy;
                    self.credentials = credentials;
                    break;
                }
                
            } else if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
                if (((NSObject <MADOperationResultStringProtocol> *)operation).success) {
                    NSString *value;
                    value = ((NSObject <MADOperationResultStringProtocol> *)operation).value.copy;
                    switch (((NSObject <MADOperationResultStringProtocol> *)operation).readOperationType) {
                        case MADKeyChainReadOperationTypeUsername:
                            username = value;
                            break;
                        case MADKeyChainReadOperationTypePassword:
                            password = value;
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }
        
        if (self.credentials == nil) {
            if (username != nil && password != nil) {
                MADCredential *credentials;
                credentials = [[MADCredential alloc] initWithUsername: username
                                                          andPassword: password];
                self.credentials = credentials;
            }
        }
    }
    
    // If we still don't have credentials, then fail.
    if (self.credentials == nil) {
        NSString *testFailed = NSLocalizedString(@"Test Failed", @"Test Failed");
        NSString *credentialsNotFound = NSLocalizedString(@"Credentials not found.", @"Credentials not found.");
        MADErrorUserInfo *errorInfo = [[MADErrorUserInfo alloc] initWithTitle: testFailed
                                                                   andMessage: credentialsNotFound];
        NSError *error = [errorInfo errorWithDomain:NSStringFromClass([self class]) code:-1];
        self.error = error;
        [self finishWithError:error];
        return;
    }
    
    MADDatabaseConnection *databaseConnection = self.databaseConnection;
    MTQuery *queryTest = [[MTQueryTest alloc] initWithObject: databaseConnection];
    MADDataTable *datatable = [MADDataTable newDataTableOfType: MADDataTableTypeVirtual
                                                  withObjectID: databaseConnection.hash];
    
    self.datatable = datatable;
    
    MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
    db.delegate = self;
    queryTest.database = db;
    self.database = db;
    
    NSError * __autoreleasing error = NULL;
    self.success = [queryTest.database executeQuery:queryTest withError:&error];
    
    _databaseConnection = nil;
    
    if (self.success) {
        [self finish];
    } else {
        if (error == NULL) {
            self.error = nil;
            [self finishWithError:nil];
        } else {
            NSError *err = error;
            self.error = error;
            [self finishWithError:err];
        }
    }
}

- (void)cleanup {
    [super cleanup];
    _credentials = nil;
    _database = nil;
    _datatable = nil;
    _databaseConnection = nil;
}

- (BOOL)displayError { return !self.success && self.error != nil; }

- (NSUInteger)tag { return self.hash; }

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    return self.credentials;
}

- (MADDataTable *)dataTableForQuery:(MTQuery *)query {
    return self.datatable;
}

@end
