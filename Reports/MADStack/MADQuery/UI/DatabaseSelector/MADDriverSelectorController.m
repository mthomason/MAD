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
#import <UIKit/UIStoryboard.h>
#import <UIKit/UILabel.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionViewController.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>

#import "MADVibrantTableView.h"

#import "MADDocumentCreationManager.h"
#import "MADDocumentCreationManagerProtocol.h"

NSString * const MADDriverSelectorControllerDefaultPrompt               = @"Select database type.";
NSString * const MADDriverSelectorControllerDefaultTitle                = @"New Report";

@interface MADDriverSelectorController ()
    <MADViewControllerStandardProtocol, MADDocumentCreationManagerProtocol, UITableViewDelegate>
    @property (nonatomic, strong) MADDocumentCreationManager *documentCreationManager;
    @property (nonatomic, weak) __kindof MADConnectionViewController *connectionViewController;

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
    
    static NSString *cellID = @"MADTableViewCellConnectionType";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];

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
    [self showViewControllerConnection:indexPath.row];
}

- (void)showViewControllerConnection:(NSInteger)type {
    NSString *storyboardName = @"MADCreateDocument";
    NSString *viewControllerID = @"MADConnectionViewControllerSQLGeneric";
    //NSString *viewControllerID = type == 0 ? @"MADConnectionViewControllerMySQL" :
    //                                         @"MADConnectionViewControllerTDS";
    NSString *nibName = type == 0 ? @"com.everydayapps.mysql" : @"com.everydayapps.tdsclient";
    NSBundle *bundle = [NSBundle bundleWithIdentifier:nibName];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName
                                                         bundle:bundle];
    MADConnectionViewController *connectionViewController;
    connectionViewController = [storyboard instantiateViewControllerWithIdentifier:viewControllerID];
    connectionViewController.delegate = self;
    connectionViewController.saveFileDelegate = self;
    connectionViewController.databaseType = type == 0 ? MADDatabaseTypeMySQL :
                                                        MADDatabaseTypeTDS;
    [self.navigationController pushViewController:connectionViewController
                                         animated:YES];
    self.connectionViewController = connectionViewController;
}

- (void)viewControllerDidFinish:(id)sender {
    if ([sender isKindOfClass:[MADConnectionViewController class]]) {
        MADDocumentCreationManager *documentCreationManager;
        MADConnectionViewController *viewController = ((MADConnectionViewController *)sender);
        MADDatabaseConnection *databaseConnection = [viewController databaseConnection];
        documentCreationManager = [[MADDocumentCreationManager alloc] initWithFilename: viewController.textFieldReportName.text
                                                                              delegate: self
                                                                    documentsDirectory: self.documentDirectory
                                                                    databaseConnection: databaseConnection
                                                                        viewController: viewController];
        [documentCreationManager start];
        self.documentCreationManager = documentCreationManager;


    }
}

- (void)viewControllerDidCancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}
- (IBAction)cancel:(id)sender {
    [self viewControllerDidCancel:sender];
}

#pragma mark -
#pragma mark MADDocumentCreationManagerProtocol

- (void)documentCreationManager:(id <MADDocumentCreationManagerInterface>)manager
                      didFinish:(BOOL)success {
    MADConnectionViewController *connectionViewController = self.connectionViewController;
    [connectionViewController resetInterface];
    if (success) {
        [self.delegate viewControllerDidFinish: self];
    } else {
        [connectionViewController enableUserInteraction];
    }
}

@end
