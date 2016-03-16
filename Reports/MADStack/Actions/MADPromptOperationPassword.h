//
//  MADPromptPasswordOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"
#import <UIKit/UIViewController.h>
#import <MAD/MADCredential.h>

@interface MADPromptOperationPassword : MADOperation

    - (instancetype)initWithViewController:(UIViewController *)viewController;

    @property (nonatomic, readonly, copy) MADCredential *credentials;
    @property (nonatomic, readonly, assign) bool gotCredentials;

    @property (nonatomic, readonly, copy) NSString *password;
    @property (nonatomic, readonly, assign) MADCredentialSource source;

    @property (nonatomic, readonly, assign) bool bypass;
    @property (nonatomic, readonly, assign) bool userContinue;

@end
