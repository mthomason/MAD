//
//  UIAlertController+CommonAlerts.m
//  MAD
//
//  Created by Michael Thomason on 10/4/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIAlertController+CommonAlerts.h"

@implementation UIAlertController (CommonAlerts)

+ (instancetype)alertNotConfiguredForEmail {
    NSString *title = NSLocalizedString(@"Alert", @"Alert title");
    NSString *message = NSLocalizedString(@"Device is not configured for email.", @"Device is not configured for email.");
    NSString *titleButton = NSLocalizedString(@"Continue", @"Continue");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle: titleButton
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];
    return alert;
}

@end
