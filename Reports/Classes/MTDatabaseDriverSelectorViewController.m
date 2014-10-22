//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseDriverSelectorViewController.h"
#import "MADVibrantTableViewCellImage.h"
#import "MTConnectionViewController.h"
#import "UIDevice+Hack.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseSqlite3.h"
#import "MADVibrantTableView.h"

NSString * const MTDatabaseDriverSelectorViewControllerDefaultPrompt    = @"Select a database type.";
NSString * const MTDatabaseDriverSelectorViewControllerDefaultTitle     = @"Supported Databases";

NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier              = @"MTSegueShowSetUpDatasourceMySqlIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier            = @"MTSegueShowSetUpDatasourceSqlite3Identifier";
NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier         = @"MTSegueShowSetUpDatasourceSalesForceIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier          = @"MTSegueShowSetUpDatasourceTdsIdentifier";

@interface MTDatabaseDriverSelectorViewController ()
    <MTViewControllerProtocol,
    MADVibrantTableViewCellDelegate,
    UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableViewCell *testCell;

@end

@implementation MTDatabaseDriverSelectorViewController

#pragma mark - MADVibrantTableViewCellDelegate

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell {
    return (UIBlurEffect *)((MADVibrantTableView *)self.tableView).visualEffectsView.effect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        self.navigationItem.prompt = NSLocalizedString(MTDatabaseDriverSelectorViewControllerDefaultPrompt, MTDatabaseDriverSelectorViewControllerDefaultPrompt);
    }

    self.navigationItem.title = NSLocalizedString(MTDatabaseDriverSelectorViewControllerDefaultTitle, MTDatabaseDriverSelectorViewControllerDefaultTitle);
    [self.navigationItem setLeftItemsSupplementBackButton: YES];
    
    self.testCell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeSqlServer"];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MADVibrantTableViewCellImage *cell = [tableView dequeueReusableCellWithIdentifier:@"MADTableViewCellConnectionType"];
    cell.vibrantTableViewCellDelegate = self;

    switch (indexPath.row) {
        case 0:
            cell.imageViewMain.image = [UIImage imageNamed:@"UIImageExportTypeMySQL"];
            cell.textLabel.text = @"";
            cell.label.text = @"MySQL Native Driver";
            cell.marginStyle = MADTableViewCellMarginStyleTop;
            break;

        case 1:
            cell.imageViewMain.image = [UIImage imageNamed:@"UIImageExportTypeSqlServer"];
            cell.textLabel.text = @"";
            cell.label.text = @"Sql Server / TDS Driver";
            cell.marginStyle = MADTableViewCellMarginStyleBottom;
            break;
            
        default:
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self performSegueWithIdentifier:MTSegueShowSetUpDatasourceMySqlIdentifier
                                      sender:self];
            break;
        case 1:
            [self performSegueWithIdentifier:MTSegueShowSetUpDatasourceSqlServerIdentifier
                                      sender:self];
            break;
            
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSString *dbId = nil;
    if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

        ((MTConnectionViewController *)segue.destinationViewController).delegate = self;
        dbId = [MTDatabaseMySql identifier];

    } else if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
    
        ((MTConnectionViewController *)segue.destinationViewController).delegate = self;
        dbId = [MTDatabaseSqlServer identifier];

    } else if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceSalesForceIdentifier]) {
    
        ((MTConnectionViewController *)segue.destinationViewController).delegate = self;
        dbId = [MTDatabaseSqlite3 identifier];

    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDatabaseType:)]) {
        [(MTConnectionViewController *)segue.destinationViewController setDatabaseType:dbId];
    }
}

- (void)viewControllerDidFinish:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

@end
