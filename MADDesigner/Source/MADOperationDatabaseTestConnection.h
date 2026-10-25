//
//  MADDatabaseOperationTest.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADDatabaseOperationTestConnection_h
#define MAD_Designer_MADDatabaseOperationTestConnection_h

#import <MADFoundation/MADOperation.h>
#import "MADOperationPromptError.h"
#import <MADFoundation/MADOperationPromptErrorProtocol.h>
#import <MADFoundation/MADOperationTestResults.h>

@class MADDatabaseConnection, MADCredential;

@interface MADOperationDatabaseTestConnection : MADOperation <MADOperationPromptErrorProtocol, MADOperationTestResults>

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection
							   credentials:(MADCredential *)credentials NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly, strong) NSError *error;
@property (nonatomic, readonly, assign, getter=isSuccess) BOOL success;

@end

#endif
