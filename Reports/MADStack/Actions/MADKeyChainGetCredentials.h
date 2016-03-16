//
//  MADKeyChainGetCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADKeyChainGetCredentials_h
#define MAD_Designer_MADKeyChainGetCredentials_h

#import "MADOperation.h"
#import <MAD/MADCredential.h>

@class MADCredential, UIViewController;

@interface MADKeyChainGetCredentials : MADOperation

    - (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController;

    @property (nonatomic, copy, readonly) MADCredential *credential;
    @property (nonatomic, assign, readonly) MADOperationState state;
    @property (nonatomic, assign) MADCredentialSource source;

@end

#endif
