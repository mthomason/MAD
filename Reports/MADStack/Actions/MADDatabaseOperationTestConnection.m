//
//  MADDatabaseOperationTest.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDatabaseOperationTestConnection.h"
#import <MAD/MADCredential.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTQueryTest.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTDataTable+Factory.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MADErrorUserInfo.h>
#import "MADKeyChainOperationGet.h"

@interface MADDatabaseOperationTestConnection ()
    <MTDatabaseProtocol>

    //Parameters
    @property (nonatomic, weak) MTDatabaseConnection *databaseConnection;
    @property (nonatomic, copy) MADCredential *credentials;

    //Store
    @property (nonatomic, strong) MTDatabase *database;
    @property (nonatomic, strong) MTDataTable *datatable;

    //Results
    @property (nonatomic, readwrite, strong) NSError *error;
    @property (nonatomic, readwrite, assign) bool success;

@end

@implementation MADDatabaseOperationTestConnection

- (void)dealloc {
    NSLog(@"Operation deallocated. %s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)connection {
    if (self = [super init]) {
        self.databaseConnection = connection;
        self.success = false;
        self.credentials = nil;
    }
    return self;
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)connection
                               credentials:(MADCredential *)credentials {
    if (self = [super init]) {
        self.databaseConnection = connection;
        self.credentials = credentials;
        self.success = false;
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
                    self.credentials = ((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).credentials;
                    break;
                }
                
            } else if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
                if (((NSObject <MADOperationResultStringProtocol> *)operation).success) {
                    switch (((NSObject <MADOperationResultStringProtocol> *)operation).readOperationType) {
                        case MADKeyChainReadOperationTypeUsername:
                            username = ((NSObject <MADOperationResultStringProtocol> *)operation).value;
                            break;
                        case MADKeyChainReadOperationTypePassword:
                            password = ((NSObject <MADOperationResultStringProtocol> *)operation).value;
                            break;
                            
                        default:
                            break;
                    }
                }
            }
        }
        
        if (self.credentials == nil) {
            if (username != nil && password != nil) {
                MADCredential *credentials = [[MADCredential alloc] initWithUsername:username andPassword:password];
                self.credentials = credentials;
            }
        }
    }
    
    // If we still don't have credentials, then fail.
    if (self.credentials == nil) {
        NSString *testFailed = NSLocalizedString(@"Test Failed", @"Test Failed");
        NSString *credentialsNotFound = NSLocalizedString(@"Credentials not found.", @"Credentials not found.");
        MADErrorUserInfo *errorInfo = [[MADErrorUserInfo alloc] initWithTitle:testFailed andMessage:credentialsNotFound];
        NSError *error = [errorInfo errorWithDomain:NSStringFromClass([self class]) code:-1];
        self.error = error;
        [self finishWithError:error];
        return;
    }
    
    MTDatabaseConnection *databaseConnection = self.databaseConnection;
    MTQuery *queryTest = [[MTQueryTest alloc] initWithObject: databaseConnection];
    MTDataTable *datatable = [MTDataTable dataTableOfType: MTDataTableTypeVirtual
                                             withObjectId: databaseConnection.hash];
    
    self.datatable = datatable;
    
    MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
    db.delegate = self;
    queryTest.database = db;
    self.database = db;
    
    NSError * __autoreleasing error = NULL;
    if ((self.success = [queryTest.database executeQuery:queryTest withError:&error])) {
        [self finish];
    } else {
        NSError *err = error;
        self.error = error;
        [self finishWithError:err];
    }
}

- (bool)displayError { return !self.success && self.error != nil; }

- (NSUInteger)tag { return self.hash; }

- (MADCredential *)getCredentialsForKey:(NSString *)key { return self.credentials; }

- (MTDataTable *)dataTableForQuery:(MTQuery *)query { return self.datatable; }

@end
