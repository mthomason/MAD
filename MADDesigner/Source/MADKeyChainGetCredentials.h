//
//  MADKeyChainGetCredentials.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADKeyChainGetCredentials_h
#define MAD_Designer_MADKeyChainGetCredentials_h

#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADCredential.h>
#import <MAD/MADCredentialSourceType.h>

@class MADCredential, UIViewController;

@interface MADKeyChainGetCredentials : MADOperation

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController;

@property (nonatomic, copy, readonly) MADCredential *credential;
@property (nonatomic, assign) MADCredentialSource source;

@end

#endif
