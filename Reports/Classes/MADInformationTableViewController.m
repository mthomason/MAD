//
//  MADInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADInformationTableViewController.h"
#import "MADTableViewCellAuto.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "UIAlertController+Constructors.h"
#import "MFMailComposeViewController+Constructors.h"
#import "ACAccountStore+Social.h"
#import "UIButton+FollowTwitter.h"
#import "UIAlertController+Constructors.h"
//#import "NSError+Constructors.h"

@interface MADInformationTableViewController ()
    <MFMailComposeViewControllerDelegate>

@end

@implementation MADInformationTableViewController

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (error) {
        UIAlertController *alertController = [UIAlertController error:error];
        [self showViewController:alertController sender:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.preferredContentSize = CGSizeMake(480, 200);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 5; }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.item) {
            
        case 1:
            [self actionWhatIsMad];
            break;
            
        case 2:
            [self actionGoToEverydayAppsCom];
            break;
            
        case 3:
            [self actionEmailUs];
            break;
            
        case 4:
            [self actionTwitterVisitEverydayApps];
            break;
            
        default:
            break;
    }
}

- (void)actionWhatIsMad {
    [self performSegueWithIdentifier:@"MADStoryboardSegueWhatIsMAD" sender:self];
}

- (void)actionGoToEverydayAppsCom {
    NSURL *eda = [NSURL URLWithString: @"https://everydayapps.com"];
    [[UIApplication sharedApplication] openURL:eda];
}

- (void)actionTwitterVisitEverydayApps {
    NSURL *eda = [NSURL URLWithString: @"https://twitter.com/EverydayApps"];
    [[UIApplication sharedApplication] openURL:eda];
}

- (void)actionEmailUs {
    MFMailComposeViewController *controller = [MFMailComposeViewController title:@"" body:@"" userInterfaceIdiom:self.traitCollection.userInterfaceIdiom];
    controller.toRecipients = @[@"admin@everydayapps.com"];
    controller.subject = @"MAD Designer";
    if (self.popoverPresentationController != nil) {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    controller.mailComposeDelegate = self;
    [self showViewController:controller sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MADTableViewCellAuto *cell = [tableView dequeueReusableCellWithIdentifier:@"MADIdentiferTableViewCellInformation" forIndexPath:indexPath];
    switch (indexPath.row) {
            
        case 0:
            cell.label.text = @"MAD Designer is software by Everyday Apps LLC";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.userInteractionEnabled = NO;
            break;
            
        case 1:
            cell.label.text = @"MAD Designer: A Breif Overview";
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.userInteractionEnabled = YES;
            break;
            
        case 2:
            cell.label.text = @"Visit our website.";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.userInteractionEnabled = YES;
            break;
            
        case 3:
            cell.label.text = @"Email Us";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.userInteractionEnabled = YES;
            break;
            
        case 4: {
            cell.label.text = @"Everyday Apps on Twitter";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            UIButton *b = [UIButton FolllowTwitterWithTarget:self action:@selector(followEverydayApps)];
            cell.accessoryView = b;
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.userInteractionEnabled = YES;
            break;
        }
        default:
            break;
    }
    cell.label.tintColor = [UIColor darkTextColor];
    [cell setNeedsLayout];
    [cell setNeedsUpdateConstraints];
    return cell;
}

- (void)followEverydayApps {
    if (self.popoverPresentationController != nil) {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    NSString *user = @"EverydayApps";
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

@end
