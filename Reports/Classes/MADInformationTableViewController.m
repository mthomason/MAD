//
//  MADInformationTableViewController.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADInformationTableViewController.h"
#import "MADTableViewCellAuto.h"
#import "UIColor+EverydayApps.h"
#import "NSAttributedString+Common.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "NSError+Constructors.h"
#import "UIAlertController+Constructors.h"

@interface MADInformationTableViewController ()

@end

@implementation MADInformationTableViewController

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
            cell.label.text = @"What is MAD Designer?  Read a breif overview:";
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
            NSAttributedString *followOnTwitter = [NSAttributedString FollowUsOnTwitter];
            UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
            b.backgroundColor = [UIColor edaBlackTwentyFivePercent];
            b.layer.cornerRadius = 5.0000f;
            b.clipsToBounds = YES;
            b.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 100.0000f, 32.0000f);
            [b addTarget:self action:@selector(followEverydayApps) forControlEvents:UIControlEventTouchUpInside];
            [b setAttributedTitle:followOnTwitter forState:UIControlStateNormal];
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
    [self twitterFollow:@"EverydayApps" completion:^(BOOL success, NSError *error) {
        if (error) {
            UIAlertController *alert = [UIAlertController error:error];
            [self presentViewController:alert animated:YES completion:NULL];
        }
    }];
}

- (void)twitterFollow:(NSString *)account completion:(void (^)(BOOL success, NSError *error))completion {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if(granted) {
            // Get the list of Twitter accounts.
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            
            // For the sake of brevity, we'll assume there is only one Twitter account present.
            // You would ideally ask the user which account they want to tweet from, if there is more than one Twitter account present.
            if (accountsArray.count > 0) {
                // Grab the initial Twitter account to tweet from.
                for (ACAccount *twitterAccount in accountsArray) {
                    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                    [tempDict setValue: @"twitter_name"
                                forKey: @"EverydayApps"];
                    [tempDict setValue: @"true"
                                forKey: @"follow"];
                    NSLog(@"*******tempDict %@*******",tempDict);
                    
                    NSURL *twitterFriendships = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"];
                    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterFriendships parameters:tempDict];
                    [postRequest setAccount:twitterAccount];
                    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        NSString *output = [NSString stringWithFormat:@"HTTP response status: %li Error %ld", (long)[urlResponse statusCode],(long)error.code];
                        NSLog(@"%@error %@", output,error.description);
                        completion(error == nil, error);
                    }];
                }
                
            } else {
                NSError *noTwitterFound = [NSError errorWithDomain: @"MADSocial"
                                                              code: 3782
                                                             title: @"No Accounts Found"
                                                        andMessage: @"Please add a Twitter account to your device."];
                completion(NO, noTwitterFound);
            }
            
        } else {
            NSError *noTwitterFound = [NSError errorWithDomain: @"MADSocial"
                                                          code: 3782
                                                         title: @"Access Denied"
                                                    andMessage: @"The software doesn't have access to your Twitter accounts.  Please check the permission in the Settings app."];
            completion(NO, noTwitterFound);
        }
    }];
}

@end
