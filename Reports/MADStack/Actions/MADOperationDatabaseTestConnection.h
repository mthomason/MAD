//
//  MADDatabaseOperationTest.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADDatabaseOperationTestConnection_h
#define MAD_Designer_MADDatabaseOperationTestConnection_h

#import <MADFoundation/MADOperation.h>
#import "MADOperationPromptError.h"
#import <MADFoundation/MADOperationPromptErrorProtocol.h>
#import <MADFoundation/MADOperationTestResults.h>

@class MADDatabaseConnection, MADCredential;

@interface MADOperationDatabaseTestConnection : MADOperation
    <MADOperationPromptErrorProtocol, MADOperationTestResults>

    - (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection;
    - (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection
                                   credentials:(MADCredential *)credentials;

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign, getter=isSuccess) BOOL success;

@end

#endif
