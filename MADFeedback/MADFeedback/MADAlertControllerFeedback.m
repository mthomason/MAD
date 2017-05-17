//
//  UIAlertController+Feedback.m
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADAlertControllerFeedback.h"

@implementation MADAlertControllerFeedback

+ (instancetype)newAlertControllerFeedbackWithHandler:(MADAlertActionHandler)handler
                                               cancel:(MADAlertActionHandler)handlerCancel {
    
    id alertController;
    UIAlertAction *actionYes, *actionCancel;
    NSString *title, *localizedTitle,
             *yes, *localizedYes,
             *cancel, *localizedCancel,
             *message, *localizedMessage;

    title = @"Feedback";
    localizedTitle = NSLocalizedString(title, title);
    
    message = @"We would love to know what you think.  "
                     @"Do you want to send us feedback?";
    localizedMessage = NSLocalizedString(message, message);
    
    yes = @"Yes";
    localizedYes = NSLocalizedString(yes, yes);

    cancel = @"Cancel";
    localizedCancel = NSLocalizedString(cancel, cancel);

    alertController = [UIAlertController alertControllerWithTitle: localizedTitle
                                                          message: localizedMessage
                                                   preferredStyle: UIAlertControllerStyleAlert];

    actionYes = [UIAlertAction actionWithTitle: localizedYes
                                         style: UIAlertActionStyleDefault
                                       handler: handler];
    actionCancel = [UIAlertAction actionWithTitle: localizedCancel
                                            style: UIAlertActionStyleCancel
                                          handler: handlerCancel];

    [alertController addAction:actionYes];
    [alertController addAction:actionCancel];

    return alertController;
}

@end
