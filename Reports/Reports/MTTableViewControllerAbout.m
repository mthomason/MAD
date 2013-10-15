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
#import "AppDelegate.h"
#import "UIApplication+Extras.h"
#import "MTViewControllerOpenDocument.h"

@interface MTTableViewControllerAbout ()
    <MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) IBOutlet UILabel *labelVersion;
@property (nonatomic, retain) IBOutlet UILabel *labelBuild;

@end

@implementation MTTableViewControllerAbout

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action {
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([UIDevice isPad]) {
        //[self setPreferredContentSize:CGSizeMake(320.0000f, 420.0000f)];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *versionTextKey = NSLocalizedString(@"Verison %@", @"Verison %@");
    NSString *buildTextKey = NSLocalizedString(@"Build %@", @"Build %@");
    NSString *version = [UIApplication version];
    NSString *versionText = [NSString stringWithFormat:versionTextKey, version];
    NSString *buildText = [NSString stringWithFormat:buildTextKey, MTGlobalBundleRev];
    [[self labelVersion] setText:versionText];
    [[self labelBuild] setText:buildText];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidCancel:self];
}

- (IBAction)composeEmail:(id)sender {
    if ([UIDevice isPad]) {
        [[self delegate] viewControllerDidRequestComposeEmail:self animated:YES];
    } else {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController	*mFMailComposeViewController = [[MFMailComposeViewController alloc] init];
            [mFMailComposeViewController setMailComposeDelegate:self];
            [mFMailComposeViewController setToRecipients:@[@"admin@everydayapps.com"]];
            [mFMailComposeViewController setSubject:@"MAD Designer"];
            [self presentViewController:mFMailComposeViewController animated:YES completion:nil];
            [mFMailComposeViewController release];
        } else {
            NSString *title = NSLocalizedString(@"Alert", @"Alert title");
            NSString *message = NSLocalizedString(@"Device is not configured for email.", @"Device is not configured for email.");
            NSString *dismiss = NSLocalizedString(@"Continue", @"Continue");
            UIAlertView *uIAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                  message:message
                                                                 delegate:self
                                                        cancelButtonTitle:dismiss
                                                        otherButtonTitles:nil];
            [uIAlertView show];
            [uIAlertView release];
        }
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

- (void)dealloc {
    [_labelVersion release];
    [_labelBuild release];
    [super dealloc];
}
@end
