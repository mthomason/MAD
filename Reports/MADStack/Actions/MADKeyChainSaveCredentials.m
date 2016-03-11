//
//  MADKeyChainSaveCredentials.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainSaveCredentials.h"

@implementation MADKeyChainSaveCredentials

- (void)saveUsername:(NSString *)username
         andPassword:(NSString *)password
              forKey:(NSString *)key
        shortCircuit:(BOOL)shortCircuit
          completion:(void(^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    /*
    if (shortCircuit == NO) {
        
        self.saveUsername = username;
        self.savePassword = password;
        
        NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
        NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];
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
