//
//  MADAboutTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADAboutTableViewController.h"

#import <CoreText/CTStringAttributes.h>
#import <MessageUI/MFMailComposeViewController.h>

#import <MAD/MADConstants.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADBlockOperation.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADAlertController.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>

#import "AppDelegate.h"

#import "MADTableViewCellBase.h"

#import "MADButtonTwitter.h"
#import "ACAccountStore+Social.h"

#import "MADOperationPromptError.h"

#import "MADAttributedStringCommon.h"

static NSString * const MADIdentifierAboutViewController = @"MADIdentifierAboutViewController";

@interface MADAboutTableViewController ()
    <MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation MADAboutTableViewController

+ (void)initialize {
    [super initialize];
    
    if (self == [MADAboutTableViewController self]) {
        @autoreleasepool {
            
            id classes;
            UINavigationBar *navigationBarMailAppearance;
            
            classes = [[NSArray alloc] initWithObjects:[MFMailComposeViewController class], nil];
            
            navigationBarMailAppearance = [UINavigationBar appearanceWhenContainedInInstancesOfClasses: classes];
            
            navigationBarMailAppearance.barTintColor = [MADColorEverydayApps newColorAnalogous4];
            navigationBarMailAppearance.tintColor = [MADColorEverydayApps newColorRed];
        }
    }
}

+ (instancetype)newAboutTableViewController {
    UIStoryboard *storyboard;
    id bundle, controller;
    bundle = [NSBundle mainBundle];
    storyboard = [UIStoryboard storyboardWithName:@"MADAbout" bundle:bundle];
    controller = [storyboard instantiateViewControllerWithIdentifier:MADIdentifierAboutViewController];
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelection = YES;
    self.preferredContentSize = CGSizeMake(320.0, 260.0);
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.tableView.backgroundColor = [UIColor clearColor];
        id blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        id blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.tableView.backgroundView = blurEffectView;
        
        UIPopoverPresentationController *popover;
        if ((popover = [self.navigationController popoverPresentationController])) {
            popover.backgroundColor = [UIColor clearColor];
        }
        self.tableView.separatorEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Exit

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToAbout:);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTSegueAboutGettingStarted"] ||
        [segue.identifier isEqualToString:@"MTSegueAboutSwipeNext"]) {
        ((MADAboutTableViewController *)segue.destinationViewController).delegate = self.delegate;
    }
}

- (NSString *)versionText {
    NSString *versionTextKey = NSLocalizedString(@"v%@", @"v%@");
    NSString *globalBundleVersion = [AppDelegate bundleVersion];
    NSString *versionText = [[NSString alloc] initWithFormat:versionTextKey, globalBundleVersion];
    return versionText;
}

- (NSString *)buildText {
    NSString *buildTextKey = NSLocalizedString(@"r%@", @"r%@");
    NSString *revision = [[MADApplication AppDelegate] revisionNumber];
    
    NSString *buildText = [[NSString alloc] initWithFormat:buildTextKey, revision];
    return buildText;
}

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {

    MADOperationQueue *operationQueue = [[MADOperationQueue alloc] init];
    MADOperationPromptError *operationErrorDisplay = [[MADOperationPromptError alloc] initWithError:error viewController:self];
    MADBlockOperation *finish = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completionBlock) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [operationErrorDisplay addDependency:finish];
    [operationQueue addOperation:operationErrorDisplay];
 
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MADTableViewCellBase *cell;
    id attributedText;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"MADTableViewCellAbout"];
    cell.frame = CGRectMake(CGPointZero.x, CGPointZero.y, self.tableView.bounds.size.width, tableView.estimatedRowHeight);

    switch (indexPath.row) {

        case 0:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.label.textColor = [MADColorEverydayApps newColorBlueDark];
            cell.label.text = NSLocalizedString([AppDelegate bundleDisplayName],
                                                [AppDelegate bundleDisplayName]);
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = NO;
            cell.marginStyle = MADTableViewCellMarginStyleTop;
            break;

        case 1: {
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = [self versionText];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
            l.text = [self buildText];
            l.font = cell.label.font;
            l.textColor = [UIColor lightGrayColor];
            cell.accessoryView = l;
            [cell.accessoryView sizeToFit];
            cell.userInteractionEnabled = NO;
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
        }

        case 2: {
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = NSLocalizedString(@"By EVERYDAY APPS LLC in Cincinnati, OH.",
                                                @"By EVERYDAY APPS LLC in Cincinnati, OH.");
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.userInteractionEnabled = NO;
            UIButton *b = [MADButtonTwitter newButtonTwitterFolllowTwitterWithTarget: self
                                                                              action: @selector(followEverydayApps)
                                                                                size: small];
            cell.accessoryView = b;
            cell.marginStyle = MADTableViewCellMarginStyleBottom;
            [cell.label sizeToFit];
            break;
        }
            
        case 3:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = NSLocalizedString([AppDelegate humanReadableCopyright],
                                                [AppDelegate humanReadableCopyright]);
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.userInteractionEnabled = NO;
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 4:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            attributedText = [MADAttributedStringCommon newAttributedStringTrademarkStatement];
            cell.label.attributedText = attributedText;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = NO;
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;

        case 5: {
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = NSLocalizedString(@"Created by Michael Thomason for Everyday Apps.",
                                                @"Created by Michael Thomason for Everyday Apps.");
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.userInteractionEnabled = NO;
            UIButton *b = [MADButtonTwitter newButtonTwitterFolllowTwitterWithTarget: self
                                                                              action: @selector(followMichael)
                                                                                size: small];
            cell.accessoryView = b;
            cell.marginStyle = MADTableViewCellMarginStyleBottom;
            [cell.label sizeToFit];
            break;
        }
        default:
            break;
    }
    [cell setNeedsLayout];
    [cell setNeedsUpdateConstraints];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)followUser:(NSString *)user {
    if (self.popoverPresentationController != nil) {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    [ACAccountStore twitterFollow:user completion:^(BOOL success, NSError *error) {
        UIAlertController *alert;
        if (!success && error) {
            alert = [MADAlertController newAlertControllerError:error];
        } else if (success) {
            NSString *title = NSLocalizedString(@"Success", @"Success");
            NSString *messageFormat = NSLocalizedString(@"You are now Twitter following user %@.",
                                                        @"You are now Twitter following user %@.");
            NSString *message = [NSString stringWithFormat:messageFormat, user];
            alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle: title
                                                                             message: message
                                                                       andCompletion: ^(UIAlertAction *action) { }];
        }
        [self presentViewController:alert animated:YES completion:NULL];
    }];
}

- (void)followEverydayApps {
    [self followUser:@"EverydayApps"];
}

- (void)followMichael {
    [self followUser:@"MichaelThomason"];
}


@end
