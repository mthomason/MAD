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

static NSString * const MADTitleSaveCredentials        = @"Save Credentials";
static NSString * const MADMessageSaveCredentials      = @"Would you like to save the credentials to your key chain?";
static NSString * const MADButtonContinue              = @"Continue";
static NSString * const MADButtonCancel                = @"Cancel";

const short errUserCancel = 1;

@interface MADKeyChainSaveCredentials()

    @property (nonatomic, weak) UIViewController *viewController;
    @property (nonatomic, copy) NSString *key;
    @property (nonatomic, strong, readwrite) MADCredential *credential;

@end

@implementation MADKeyChainSaveCredentials

- (instancetype)initWithKey:(NSString *)key viewController:(UIViewController *)viewController {
    if (self = [super init]) {
        self.viewController = viewController;
        self.key = key.copy;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }


- (void)execute {
        
    MADCredentialSource source = none;
    NSArray *dependencies = self.dependencies;
    for (MADKeyChainGetCredentials *dependency in dependencies) {
        if ([dependency isKindOfClass:[MADKeyChainGetCredentials class]]) {
            self.credential = ((MADKeyChainGetCredentials *)dependency).credential.copy;
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
                    [self finish];
                } else {
                    NSError *error = [NSError errorWithDomain:@"MADOSStatus" code:status userInfo:nil];
                    [self finishWithError:error];
                };
            }];
            break;
        }
        case password_prompt: {
            
            
            [self promptToSave:^(UIAlertAction *action) {
                OSStatus status = [MTKeyChain savePassword: self.credential.password
                                                    forKey: self.key];
                if (status == errSecSuccess) {
                    [self finish];
                } else {
                    NSError *error = [NSError errorWithDomain:@"MADOSStatus" code:status userInfo:nil];
                    [self finishWithError:error];
                }

            }];
            
            break;
        }
        case keychain:
            [self finish];
            
        default:
            [self finish];
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

@end
