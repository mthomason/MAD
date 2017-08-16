//
//  MADOperationGetCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationGetCredentials_h
#define MAD_Designer_MADOperationGetCredentials_h

#import <MADFoundation/MADGroupOperation.h>
#import <MAD/MADCredential.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import "MADKeyChainKeyValueProtocol.h"

@class UIViewController, MADDatabaseConnection, MADCredential;

@interface MADOperationGetCredentials : MADGroupOperation
    <MADOperationHoldsCredentialsProtocol, MADKeyChainKeyValueProtocol>

    - (instancetype)initWithDatabaseConnection: (MADDatabaseConnection *)databaseConnection
                                viewController: (UIViewController *)viewController;
    @property (readonly) MADCredential *credentials;
    @property (readonly) BOOL gotCredentials;
    @property (readonly) BOOL manuallyInputtedCredentials;

@end

#endif
