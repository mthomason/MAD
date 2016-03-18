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

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    if (!self.credentials) {
        [self setStateError];
    }
    MADCredential *credentialsCopy = self.credentials.copy;
    return credentialsCopy;
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)connection {
    if (self = [super init]) {
        self.databaseConnection = connection;
        self.success = false;
        self.credentials = nil;
    }
    return self;
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)connection credentials:(MADCredential *)credentials {
    if (self = [super init]) {
        self.databaseConnection = connection;
        self.credentials = credentials;
        self.success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    
    if (self.credentials == nil) {
        for (NSOperation *operation in self.dependencies) {
            if ([operation conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
                if (((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).gotCredentials) {
                    self.credentials = ((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).credentials;
                    break;
                }
            }
        }
    }
    
    MTDatabaseConnection *databaseConnection = self.databaseConnection;
    MTQuery *queryTest = [[MTQueryTest alloc] initWithObject: databaseConnection];
    
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(databaseConnection.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    MTDataTable *datatable = [MTDataTable dataTableFactory:parameters];
    
    self.datatable = datatable;
    
    MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
    db.delegate = self;
    queryTest.database = db;
    self.database = db;
    
    NSError * __autoreleasing error = NULL;
    if ((self.success = [queryTest.database executeQuery:queryTest withError:&error])) {
        [self finish];
    } else {
        self.error = error;
        [self finishWithError:error];
    }
    
}

@end
