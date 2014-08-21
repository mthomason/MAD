//
//  MTTableViewControllerAbout.m
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerAbout.h"
#import <MessageUI/MessageUI.h>
#import "MTApplicationInstance.h"
#import "UIApplication+Extras.h"
#import "MTViewControllerOpenDocument.h"
#import "UIDevice+Hack.h"
#import "NSError+UserInterface.h"

#import "UIColor+EverydayApps.h"
#import <CoreText/CoreText.h>

@interface MTTableViewControllerAbout ()
    <MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *labelTitle;
@property (nonatomic, weak) IBOutlet UILabel *labelVersion;
@property (nonatomic, weak) IBOutlet UILabel *labelBuild;
@property (nonatomic, weak) IBOutlet UILabel *labelTrademark;

@end

@implementation MTTableViewControllerAbout

#pragma mark - Exit

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToAbout:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToAbout:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (CGSize)preferredContentSize {
    CGSize preferredContentSize;
    if ([UIDevice isPad]) {
        preferredContentSize = CGSizeMake(540.0000f, 556.0000f);
        [[self navigationController] setPreferredContentSize:preferredContentSize];
        [[[self navigationController] view] setNeedsLayout];
    } else {
        preferredContentSize = [super preferredContentSize];
    }
    return preferredContentSize;
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
    [[self labelTrademark] setNumberOfLines:0];
    [[self labelTrademark] setLineBreakMode:NSLineBreakByWordWrapping];
    [[self labelTrademark] setAttributedText:[self trademarkStatement]];
    [[self labelTrademark] sizeToFit];
    //[[[self navigationController] toolbar] setBarTintColor:[UIColor tintColorBlue]];
}

- (NSAttributedString *)trademarkStatement {
    NSNumber *superscript = @(1);
    UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    NSDictionary *attributes = @{(__bridge NSString *)kCTSuperscriptAttributeName : superscript, NSFontAttributeName : font};
    NSAttributedString *r = [[NSAttributedString alloc] initWithString:@"®" attributes:attributes];
    NSAttributedString *mad = [[NSAttributedString alloc] initWithString:@"MAD" attributes:nil];
    NSMutableAttributedString *tm = [[NSMutableAttributedString alloc] initWithAttributedString:mad];
    [tm appendAttributedString:r];
    NSAttributedString *statement = [[NSAttributedString alloc] initWithString:@" is a registered trademark of Everyday Apps LLC." attributes:nil];
    [tm appendAttributedString:statement];
    return tm;
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidCancel: self];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidCancel: self];
}

- (IBAction)composeEmail:(id)sender {
    if ([UIDevice isPad]) {
        [[self delegate] viewControllerDidRequestComposeEmail: self
                                                     animated: YES];
    } else {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController	*mFMailComposeViewController = [[MFMailComposeViewController alloc] init];
            [mFMailComposeViewController setMailComposeDelegate:self];
            [mFMailComposeViewController setToRecipients:@[@"admin@everydayapps.com"]];
            [mFMailComposeViewController setSubject:@"MAD Designer"];
            [self presentViewController:mFMailComposeViewController animated:YES completion:nil];
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
        [(MTTableViewControllerAbout *)segue.destinationViewController setDelegate:[self delegate]];
    }
}

@end
