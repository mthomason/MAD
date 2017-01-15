//
//  MADDatabaseOperationTest.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADDatabaseOperationTestConnection_h
#define MAD_Designer_MADDatabaseOperationTestConnection_h

#import "MADOperation.h"
#import "MADPromptOperationDisplayError.h"

@class MADDatabaseConnection;
@class MADCredential;

@protocol MADOperationDatabaseTestConnectionProtocol <NSObject>

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign) BOOL success;

@end

@interface MADOperationDatabaseTestConnection : MADOperation
    <MADPromptOperationDisplayErrorProtocol, MADOperationDatabaseTestConnectionProtocol>

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign) BOOL success;

    - (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection;
    - (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection
                                   credentials:(MADCredential *)credentials;

@end

#endif
