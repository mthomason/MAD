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
#import <UIKit/UIKit.h>
#import "UIApplication+Helpers.h"

typedef void (^MTBlockErrorDismiss)(NSInteger buttonIndex);

@implementation NSError (Constructors)

+ (instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code title:(NSString *)title andMessage:(NSString *)message {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : message,
                                NSLocalizedFailureReasonErrorKey : title};
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSDictionary *)userInfoWithTitle:(NSString *)title andMessage:(NSString *)message {
    return @{NSLocalizedDescriptionKey :         title,
             NSLocalizedFailureReasonErrorKey :  message};
    
}

- (void)presentErrorOnViewController:(UIViewController *)viewController {
    
    if (viewController == nil) {
        viewController = [UIApplication topViewController];
    }
    
    NSString *dismissButtonTitle = NSLocalizedString(@"Dismiss", @"Dismiss");
    NSString *localizedDescription = [self localizedDescription];
    NSString *localizedFailureReason = [self localizedFailureReason];
    NSError *underlyingError = [self userInfo][NSUnderlyingErrorKey];
    NSString *underlyingLocalizedDescription = [underlyingError localizedDescription];
    NSString *underlyingLocalizedFailureReason = [underlyingError localizedFailureReason];
    if (underlyingLocalizedDescription != nil) {
        localizedDescription = underlyingLocalizedDescription;
        localizedFailureReason = underlyingLocalizedFailureReason;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: localizedFailureReason
                                                                   message: localizedDescription
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle: dismissButtonTitle
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];
    
    
    
}

@end
