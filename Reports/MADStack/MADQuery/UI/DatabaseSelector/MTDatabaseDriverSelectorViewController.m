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

#import <MAD/MTDatabaseConnection.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MUIViewControllerDelegate.h"

#import "MADVibrantTableView.h"
#import "MADTransparentPresentationController.h"
#import "MADNavigationBarTitleView.h"
#import "MTConnectionViewController.h"

#import <UIKit/UIImage.h>
#import <UIKit/UIVisualEffectView.h>

NSString * const MTDatabaseDriverSelectorViewControllerDefaultPrompt    = @"Select database type.";
NSString * const MTDatabaseDriverSelectorViewControllerDefaultTitle     = @"New Report";

NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier              = @"MTSegueShowSetUpDatasourceMySqlIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier            = @"MTSegueShowSetUpDatasourceSqlite3Identifier";
NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier         = @"MTSegueShowSetUpDatasourceSalesForceIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier          = @"MTSegueShowSetUpDatasourceTdsIdentifier";

@interface MTDatabaseDriverSelectorViewController ()
    <MTViewControllerProtocol,
        UITableViewDelegate>

    @property (weak, nonatomic) IBOutlet UITableViewCell *testCell;

@end

@implementation MTDatabaseDriverSelectorViewController

- (NSURL *)documentDirectory {
    NSURL *url = [self.saveFileDelegate documentDirectory];
    return  url;
}

#pragma mark - MADVibrantTableViewCellDelegate

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell {
    return (UIBlurEffect *)((MADVibrantTableView *)self.tableView).visualEffectsView.effect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.prompt = NSLocalizedString(MTDatabaseDriverSelectorViewControllerDefaultPrompt, MTDatabaseDriverSelectorViewControllerDefaultPrompt);
    self.navigationItem.title = NSLocalizedString(MTDatabaseDriverSelectorViewControllerDefaultTitle, MTDatabaseDriverSelectorViewControllerDefaultTitle);
    [self.navigationItem setLeftItemsSupplementBackButton: YES];
    
    self.testCell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeSqlServer"];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = YES;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = @"New Report";
    self.navigationItem.titleView = titleView;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 2; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MADTableViewCellConnectionType"];
    //cell.vibrantTableViewCellDelegate = self;

    switch (indexPath.row) {
        case 0:
            cell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeMySQL"];
            cell.textLabel.text = @"MySQL Native Driver";
            break;

        case 1:
            cell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeSqlServer"];
            cell.textLabel.text = @"Sql Server / TDS Driver";
            break;
            
        default:
            break;
    }
    UIColor *newBlue = [MADColorEverydayApps newColorBlue];
    [UITableViewCell appearance].textLabel.highlightedTextColor = newBlue;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 104.000f; }

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
            [self performSegueWithIdentifier: MTSegueShowSetUpDatasourceMySqlIdentifier sender: self];
            break;
            
        case 1:
            [self performSegueWithIdentifier: MTSegueShowSetUpDatasourceSqlServerIdentifier sender: self];
            break;
            
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSString *dbId = nil;
    if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

        ((MADConnectionViewController *)segue.destinationViewController).delegate = self;
        ((MADConnectionViewController *)segue.destinationViewController).saveFileDelegate = self;
        dbId = MADIdentifierDatabaseMySQL;

    } else if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
    
        ((MADConnectionViewController *)segue.destinationViewController).delegate = self;
        ((MADConnectionViewController *)segue.destinationViewController).saveFileDelegate = self;
        dbId = MADIdentifierDatabaseTDS;

    } else if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceSalesForceIdentifier]) {
    
        ((MADConnectionViewController *)segue.destinationViewController).delegate = self;
        ((MADConnectionViewController *)segue.destinationViewController).saveFileDelegate = self;
        dbId = MADIdentifierDatabaseSqlite3;

    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDatabaseType:)]) {
        [(MADConnectionViewController *)segue.destinationViewController setDatabaseType:dbId];
    }
}

- (void)viewControllerDidFinish:(id)sender {
    [self.delegate viewControllerDidFinish:self];
}

- (void)viewControllerDidCancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}
- (IBAction)cancel:(id)sender {
    [self viewControllerDidCancel:sender];
}

@end
