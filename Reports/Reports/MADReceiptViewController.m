//
//  UIReceiptViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/21/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReceiptViewController.h"
#import "MTVerificationController.h"
#import "MADReceiptApplication.h"
#import "UIAlertController+Constructors.h"
#import "MADReceiptTableViewCell.h"

@interface MADReceiptViewController ()

@end

@implementation MADReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [MTVerificationController sharedInstance].receipt == nil ? 0 : [MTVerificationController sharedInstance].receipt.inAppPurchases.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseID = @"MADIdentifierReceipt";
    MADReceiptTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID forIndexPath:indexPath];
    NSDictionary *purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[indexPath.item];
    cell.labelID.text = purchase[@"product-id"];
    cell.labelOriginalPurchaseDate.text = purchase[@"original-purchase-date"];
    cell.labelOriginalPurchaseDate.text = purchase[@"purchase-date"];
    cell.labelCancellationDate.text = purchase[@"cancellation-date"];

    
    if (cell.labelCancellationDate.text.length > 0) {
        cell.labelCancellationLabel.textColor = [UIColor redColor];
        cell.labelCancellationLabel.hidden = NO;
    } else {
        cell.labelCancellationLabel.hidden = YES;
    }
    return cell;
}

- (IBAction)actionRefresh:(id)sender {
    [[MTVerificationController sharedInstance] refreshReceipt:^(BOOL success, NSError *error) {
        if (error != nil) {
            UIAlertController *alert = [UIAlertController error:error];
            [self presentViewController:alert animated:YES completion:^{
                
            }];
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)actionDone:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *purchase = [MTVerificationController sharedInstance].receipt.inAppPurchases[indexPath.item];
    NSString *cancelDate = purchase[@"cancellation-date"];
    return cancelDate.length > 0 ? 100.0000f : 74.0000f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
