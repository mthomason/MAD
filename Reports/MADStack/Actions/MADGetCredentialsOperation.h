//
//  MADGetCredentialsOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADGetCredentialsOperation_h
#define MAD_Designer_MADGetCredentialsOperation_h

#import "MADGroupOperation.h"
#import <MAD/MADCredential.h>

@class UIViewController, MTDatabaseConnection, MADCredential;

@interface MADGetCredentialsOperation : MADGroupOperation
    <MADOperationHoldsCredentialsProtocol>

    - (instancetype)initWithDatabaseConnection: (MTDatabaseConnection *)databaseConnection
                                viewController: (UIViewController *)viewController;
    @property (readonly) MADCredential *credentials;
    @property (readonly) bool gotCredentials;

@end

#endif
