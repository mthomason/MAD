//
//  MADDatabaseOperationTest.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADDatabaseOperationTestConnection_h
#define MAD_Designer_MADDatabaseOperationTestConnection_h

#import <MADFoundation/MADOperation.h>
#import "MADOperationPromptError.h"
#import "MADOperationPromptErrorProtocol.h"
#import "MADOperationDatabaseTestConnectionProtocol.h"

@class MADDatabaseConnection, MADCredential;

@interface MADOperationDatabaseTestConnection : MADOperation
    <MADOperationPromptErrorProtocol, MADOperationDatabaseTestConnectionProtocol>

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign) BOOL success;

    - (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection;
    - (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection
                                   credentials:(MADCredential *)credentials;

@end

#endif
