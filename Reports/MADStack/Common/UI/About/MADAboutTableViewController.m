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

#import "MADAboutTableViewController.h"
#import "MADTableViewCellBase.h"

#import "UIButton+FollowTwitter.h"
#import "ACAccountStore+Social.h"

#import "MADOperationQueue.h"
#import "MADPromptOperationDisplayError.h"
#import "MADBlockOperation.h"

#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

#import <CoreText/CTStringAttributes.h>

@interface MADAboutTableViewController ()
    <MFMailComposeViewControllerDelegate,
        UITableViewDelegate,
        UITableViewDataSource>

@end

@implementation MADAboutTableViewController

#pragma mark - Exit

- (IBAction)unwindToAbout:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToAbout:);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelection = YES;
    self.preferredContentSize = CGSizeMake(320.0000f, 260.0000f);
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (NSString *)versionText {
    NSString *versionTextKey = NSLocalizedString(@"v%@", @"v%@");
    NSString *globalBundleVersion = [[MADApplication AppDelegate] versionNumber];
    NSString *versionText = [NSString stringWithFormat:versionTextKey, globalBundleVersion];
    return versionText;
}

- (NSString *)buildText {
    NSString *buildTextKey = NSLocalizedString(@"r%@", @"r%@");
    NSString *revision = [[MADApplication AppDelegate] revisionNumber];
    NSString *buildText = [NSString stringWithFormat:buildTextKey, revision];
    return buildText;
}

- (NSAttributedString *)trademarkStatement {
    NSNumber *superscript = @(1);
    UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    NSDictionary *attributes = @{(__bridge NSString *)kCTSuperscriptAttributeName : superscript,
                                 NSFontAttributeName : font};
    NSAttributedString *r = [[NSAttributedString alloc] initWithString: @"®"
                                                            attributes: attributes];
    NSAttributedString *mad = [[NSAttributedString alloc] initWithString: MADTrademark
                                                              attributes: nil];
    
    NSMutableAttributedString *tm = [[NSMutableAttributedString alloc] initWithAttributedString: mad];
    [tm appendAttributedString:r];
    
    NSAttributedString *statement = [[NSAttributedString alloc] initWithString: @" is a registered trademark of Everyday Apps LLC."
                                                                    attributes: nil];
    [tm appendAttributedString: statement];
    
    return tm;
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
    MADPromptOperationDisplayError *operationErrorDisplay = [[MADPromptOperationDisplayError alloc] initWithError:error viewController:self];
    MADBlockOperation *finish = [[MADBlockOperation alloc] initWithBlock:^(OperationCompletionBlock completionBlock) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [operationErrorDisplay addDependency:finish];
    [operationQueue addOperation:operationErrorDisplay];
 
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MTSegueAboutGettingStarted"] ||
        [segue.identifier isEqualToString:@"MTSegueAboutSwipeNext"]) {
        ((MADAboutTableViewController *)segue.destinationViewController).delegate = self.delegate;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MADTableViewCellBase *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"MADTableViewCellAbout"];
    cell.frame = CGRectMake(CGPointZero.x, CGPointZero.y, self.tableView.bounds.size.width, tableView.estimatedRowHeight);
    switch (indexPath.row) {

        case 0:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.label.textColor = [MADColorEverydayApps newColorBlueDark];
            cell.label.text = @"MAD Designer";
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
            cell.label.text = @"By EVERYDAY APPS LLC in Cincinnati, OH.";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.userInteractionEnabled = NO;
            UIButton *b = [UIButton FolllowTwitterWithTarget:self action:@selector(followEverydayApps) size:small];
            cell.accessoryView = b;
            cell.marginStyle = MADTableViewCellMarginStyleBottom;
            [cell.label sizeToFit];
            break;
        }
            
        case 3:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = @"Copyright EVERYDAY APPS LLC 2015.  All rights reserved.";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.userInteractionEnabled = NO;
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;
            
        case 4:
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.attributedText = [self trademarkStatement];
            cell.label.textColor = [UIColor darkGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = NO;
            cell.marginStyle = MADTableViewCellMarginStyleMiddle;
            break;

        case 5: {
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.label.text = @"Created by Michael Thomason for Everyday Apps.";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.textColor = [UIColor darkGrayColor];
            cell.userInteractionEnabled = NO;
            UIButton *b = [UIButton FolllowTwitterWithTarget:self action:@selector(followMichael) size:small];
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
            alert = [UIAlertController error:error];
        } else if (success) {
            NSString *title = NSLocalizedString(@"Success", @"Success");
            NSString *messageFormat = NSLocalizedString(@"You are now Twitter following user %@.",
                                                        @"You are now Twitter following user %@.");
            NSString *message = [NSString stringWithFormat:messageFormat, user];
            alert = [UIAlertController errorDisplayErrorWithTitle: title
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
