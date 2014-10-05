//
//  MTViewControllerAbout.m
//  MAD
//
//  Created by Michael Thomason on 8/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerAbout.h"
#import <MessageUI/MessageUI.h>
#import "NSError+UserInterface.h"
#import "UIColor+EverydayApps.h"
#import "UIAlertController+CommonAlerts.h"

@interface MTViewControllerAbout ()
    <MFMailComposeViewControllerDelegate>

@end

@implementation MTViewControllerAbout

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

- (IBAction)composeEmail:(id)sender {

    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController	*mFMailComposeViewController = [[MFMailComposeViewController alloc] init];
        mFMailComposeViewController.mailComposeDelegate = self;
        mFMailComposeViewController.toRecipients = @[@"admin@everydayapps.com"];
        mFMailComposeViewController.subject = @"MAD Designer";
        mFMailComposeViewController.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
        [self presentViewController:mFMailComposeViewController animated:YES completion:nil];
    } else {
        
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    [error presentErrorOnViewController:self];
}

@end
