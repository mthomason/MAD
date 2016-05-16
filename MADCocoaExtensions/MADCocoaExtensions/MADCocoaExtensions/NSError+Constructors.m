//
//  NSError+Constructors.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "NSError+Constructors.h"
#import "UIApplication+Helpers.h"
#import "MADThread.h"

#import <UIKit/UIAlertController.h>

typedef void (^MTBlockErrorDismiss)(NSInteger buttonIndex);

@implementation NSError (Constructors)

+ (void)presentError:(NSError *)error onViewController:(UIViewController *)viewController
          completion:(void (^)(BOOL success))completion {
    
    if (error == nil) {
        completion(YES);
        return;
    }

    UIViewController *displayController;
    if (viewController == nil) {
        displayController = [MADStackViewController topViewController];
    } else {
        displayController = viewController;
    }
    
    NSString *dismissButtonTitle = NSLocalizedString(@"Dismiss", @"Dismiss");
    NSString *localizedDescription = error.localizedDescription;
    NSString *localizedFailureReason = error.localizedFailureReason;
    
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    
    if (underlyingError.localizedDescription != nil) {
        localizedDescription = underlyingError.localizedDescription;
        localizedFailureReason = underlyingError.localizedFailureReason;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: localizedFailureReason
                                                                   message: localizedDescription
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle: dismissButtonTitle style: UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                                                   if (completion) {
                                                       completion(YES);
                                                   }
                                               }];
    [alert addAction:ok];
    displayController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [displayController presentViewController:alert animated:YES completion:NULL];
    
}

@end
