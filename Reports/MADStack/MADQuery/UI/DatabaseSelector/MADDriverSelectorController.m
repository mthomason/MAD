//
//  UITableViewControllerDataSourceTypes.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDriverSelectorController.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UIStoryboardSegue.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "MADViewControllerStandardProtocol.h"

#import "MADVibrantTableView.h"
#import "MADConnectionViewController.h"
#import "MADLabelTitle.h"

NSString * const MADDriverSelectorControllerDefaultPrompt               = @"Select database type.";
NSString * const MADDriverSelectorControllerDefaultTitle                = @"New Report";

NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier              = @"MTSegueShowSetUpDatasourceMySqlIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier          = @"MTSegueShowSetUpDatasourceSqlServerIdentifier";

@interface MADDriverSelectorController ()
    <MADViewControllerStandardProtocol,
        UITableViewDelegate>

    @property (weak, nonatomic) IBOutlet UITableViewCell *testCell;

@end

@implementation MADDriverSelectorController

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
    
    self.testCell.imageView.image = [UIImage imageNamed:@"UIImageExportTypeSqlServer"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 44.0000f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = YES;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
                                         forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell
                                              forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.row) {

        case 0:
            [self performSegueWithIdentifier: MTSegueShowSetUpDatasourceMySqlIdentifier
                                      sender: self];
            break;
            
        case 1:
            [self performSegueWithIdentifier: MTSegueShowSetUpDatasourceSqlServerIdentifier
                                      sender: self];
            break;
            
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    MADDatabaseType dbId;
    if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

        ((MADConnectionViewController *)segue.destinationViewController).delegate = self;
        ((MADConnectionViewController *)segue.destinationViewController).saveFileDelegate = self;
        dbId = MADDatabaseTypeMySQL;

    } else if ([segue.identifier isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
    
        ((MADConnectionViewController *)segue.destinationViewController).delegate = self;
        ((MADConnectionViewController *)segue.destinationViewController).saveFileDelegate = self;
        dbId = MADDatabaseTypeTDS;

    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDatabaseType:)]) {
        ((MADConnectionViewController *)segue.destinationViewController).databaseType = dbId;
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
