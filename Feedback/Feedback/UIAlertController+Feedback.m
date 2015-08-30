//
//  UIAlertController+Feedback.m
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIAlertController+Feedback.h"

@implementation UIAlertController (Feedback)

+ (instancetype)solicateFeedbackWithHandler:(void (^)(UIAlertAction *action))handler
                                     cancel:(void (^)(UIAlertAction *action))handlerCancel {
    NSString *title = NSLocalizedString(@"Feedback", @"Feedback");
    NSString *message = NSLocalizedString(@"We would love to know what you think.  Do you want to send us feedback?", @"We would love to know what you think.  Do you want to send us feedback?");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    NSString *yes = NSLocalizedString(@"Yes", @"Yes");
    NSString *cancel = NSLocalizedString(@"Cancel", @"Cancel");
    UIAlertAction *actionYes = [UIAlertAction actionWithTitle:yes style:UIAlertActionStyleDefault handler:handler];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:handlerCancel];
    [alertController addAction:actionYes];
    [alertController addAction:actionCancel];
    return alertController;
}

@end
