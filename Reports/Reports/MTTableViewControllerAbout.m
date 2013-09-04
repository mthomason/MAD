//
//  MTTableViewControllerAbout.m
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewControllerAbout.h"
#import <MessageUI/MessageUI.h>
#import "NSError+UserInterface.h"

@interface MTTableViewControllerAbout ()
    <MFMailComposeViewControllerDelegate>

@end

@implementation MTTableViewControllerAbout

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action {
    
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

- (IBAction)composeEmail:(id)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController	*mFMailComposeViewController = [[MFMailComposeViewController alloc] init];
        [mFMailComposeViewController setMailComposeDelegate:self];
        [mFMailComposeViewController setToRecipients:@[@"admin@everydayapps.com"]];
        [mFMailComposeViewController setSubject:@"MAD Designer"];
        [self presentViewController:mFMailComposeViewController animated:YES completion:nil];
        [mFMailComposeViewController release];
    } else {
        UIAlertView *uIAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert", @"Alert title")
                                                              message:NSLocalizedString(@"Device is not configured for email.", @"Device is not configured for email.")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Continue", @"Continue")
                                                    otherButtonTitles:nil];
        [uIAlertView show];
        [uIAlertView release];
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    [error presentErrorToUser];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"MTSegueAboutGettingStarted"] ||
        [[segue identifier] isEqualToString:@"MTSegueAboutSwipeNext"]) {
        [[segue destinationViewController] setDelegate:[self delegate]];
    }
}

@end
