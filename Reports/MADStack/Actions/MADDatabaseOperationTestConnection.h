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

@class MTDatabaseConnection;
@class MADCredential;

@protocol MADDatabaseOperationTestConnectionProtocol <NSObject>

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign) bool success;

@end

@interface MADDatabaseOperationTestConnection : MADOperation
    <MADPromptOperationDisplayErrorProtocol, MADDatabaseOperationTestConnectionProtocol>

    @property (nonatomic, readonly, strong) NSError *error;
    @property (nonatomic, readonly, assign) bool success;

    - (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)connection;
    - (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)connection
                                   credentials:(MADCredential *)credentials;

@end

#endif
