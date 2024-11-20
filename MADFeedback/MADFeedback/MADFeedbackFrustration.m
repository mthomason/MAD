//
//  MADFeedbackFrustration.m
//  MADFeedback
//
//  Created by Michael Thomason on 8/28/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFeedbackFrustration.h"

#import <MessageUI/MessageUI.h>

#import <MADCocoaExtensions/UIViewController+Utilities.h>
#import <MADCocoaExtensions/MADAlertController.h>

#import "MADAlertControllerFeedback.h"

@interface MADFeedbackFrustration()
    <MFMailComposeViewControllerDelegate>

@end

@implementation MADFeedbackFrustration

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.subtype == UIEventSubtypeMotionShake) {

        UIViewController *topMostController = [UIViewController copyTopmostViewController];
        UIAlertController *alertController = [MADAlertControllerFeedback newAlertControllerFeedbackWithHandler:^(UIAlertAction *action) {
            
            
            MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.subject = NSLocalizedString(@"Feedback for MAD Designer",
                                                     @"Feedback for MAD Designer");
            [mailComposer setMessageBody:@"" isHTML:NO];
            NSString *emailAddress = @"admin@everydayapps.com";
            NSArray *to = @[emailAddress];
            mailComposer.toRecipients = to;
            mailComposer.mailComposeDelegate = self;
            [topMostController presentViewController:mailComposer animated:YES completion:^{}];
        } cancel:^(UIAlertAction *action) {
            
        }];
        [topMostController presentViewController:alertController animated:YES completion:^{}];
        
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

    UIViewController *topMostController = [UIViewController copyTopmostViewController];
    if (error) {
        UIAlertController *alertController = [MADAlertController newAlertControllerError:error];
        [topMostController showViewController:alertController sender:self];
    } else {
        [topMostController dismissViewControllerAnimated:YES completion:^{ }];
    }
}

@end
