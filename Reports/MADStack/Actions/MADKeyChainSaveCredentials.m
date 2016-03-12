//
//  MADKeyChainSaveCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainSaveCredentials.h"
#import <MAD/MADCredential.h>
#import <MAD/MTKeyChain.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>
#import "MADKeyChainGetCredentials.h"

NSString * const MADTitleSaveCredentials        = @"Save Credentials";
NSString * const MADMessageSaveCredentials      = @"Would you like to save the credentials to your "
                                                        @"key chain?";
NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

@interface MADKeyChainSaveCredentials()

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, copy) NSString *key;
    @property (nonatomic, strong, readwrite) MADCredential *credential;
    //@property (nonatomic, strong) MTKeyChain *keychain;

@end

@implementation MADKeyChainSaveCredentials

- (instancetype)initWithCredentials:(MADCredential *)credentials key:(NSString *)key viewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.credential = credentials.copy;
        self.viewController = viewController;
        self.key = key.copy;
        [self setStateReady];
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)start {
    
    if ([self isCancelled]) {
        [self setStateCanceled];
        return;
    }
    
    [self setStateExecuting];
    
    MADCredentialSource source = none;
    NSArray *dependencies = self.dependencies;
    for (MADKeyChainGetCredentials *dependency in dependencies) {
        if ([dependency isKindOfClass:[MADKeyChainGetCredentials class]]) {
            source = ((MADKeyChainGetCredentials *)dependency).source;
            break;
        }
    }
    
    switch (source) {
        case credential_prompt: {
            [self promptToSave:^(UIAlertAction *action) {
                OSStatus status = [MTKeyChain saveUsername: self.credential.username
                                               andPassword: self.credential.password
                                                    forKey: self.key];
                if (status == errSecSuccess) {
                    [self setStateFinished];
                } else {
                    [self setStateError];
                }
            }];
            break;
        }
        case password_prompt: {
            [self promptToSave:^(UIAlertAction *action) {
                OSStatus status = [MTKeyChain savePassword: self.credential.password
                                                    forKey: self.key];
                if (status == errSecSuccess) {
                    [self setStateFinished];
                } else {
                    [self setStateError];
                }

            }];
            break;
        }
        case keychain:
            [self setStateFinished];
            
        default:
            [self setStateFinished];
            break;
    }
    
}

- (void)promptToSave:(void (^ __nullable)(UIAlertAction *action))actionContinue {
    
    NSString *title = NSLocalizedString(MADTitleSaveCredentials, MADTitleSaveCredentials);
    NSString *message = NSLocalizedString(MADMessageSaveCredentials, MADMessageSaveCredentials);
    NSString *ok = NSLocalizedString(MADButtonContinue, MADButtonContinue);
    NSString *cancel = NSLocalizedString(MADButtonCancel, MADButtonCancel);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *alertActionContinue = [UIAlertAction actionWithTitle: ok
                                                                  style: UIAlertActionStyleDefault
                                                                handler: actionContinue];
    
    void (^ __nullable actionCancel)(UIAlertAction *action) = ^(UIAlertAction *action) {

    };
    
    UIAlertAction *alertActionCancel = [UIAlertAction actionWithTitle: cancel
                                                                style: UIAlertActionStyleCancel
                                                              handler: actionCancel];
    
    [alertController addAction:alertActionContinue];
    [alertController addAction:alertActionCancel];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIViewController *topViewController = self.viewController;
        topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [topViewController  presentViewController: alertController animated: YES completion: nil];
    }];
}

- (void)saveUsername:(NSString *)username
         andPassword:(NSString *)password
              forKey:(NSString *)key
        shortCircuit:(BOOL)shortCircuit
          completion:(void(^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    
    NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];

    
    /*
    if (shortCircuit == NO) {
        
        self.saveUsername = username;
        self.savePassword = password;
        
        if (keyUsername == nil || keyPassword == nil ||
            ![username isEqualToString:keyUsername] ||
            ![password isEqualToString:keyPassword]) {
            
            UIAlertController *alertController = [UIAlertController saveCredentials:^(UIAlertAction *action) {
                
                [MTKeyChain saveUsername: self.saveUsername
                             andPassword: self.savePassword
                                  forKey: key];
                
                completion(YES, nil, self.saveUsername, self.savePassword);
                
            } cancel:^(UIAlertAction *action) {
                completion(NO, nil, nil, nil);
            }];
            
            [MADThread safeSwitchToMainThread:^{
                UIViewController *topViewController = [MADStackViewController topViewController];
                topViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                [topViewController  presentViewController: alertController animated: YES completion: nil];
            }];
            
        }
        
    } else {
        completion(YES, nil, username, password);
    }
    */
}

@end
