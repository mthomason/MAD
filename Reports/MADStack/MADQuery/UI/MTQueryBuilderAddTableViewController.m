//
//  UIViewControllerSchemaAddTable.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderAddTableViewController.h"

@implementation MTQueryBuilderAddTableViewController

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish: self];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellTableName";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    
    RptqDatabaseSchemaTable *tablea = [[self fetchedResultsController] objectAtIndexPath: indexPath];
    [[cell textLabel] setText: [tablea name]];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqDatabaseSchemaTable *tablea = [[self fetchedResultsController] objectAtIndexPath: indexPath];
    [self.delegate viewControllerSchemaAddTableDidSelectTable: tablea];
}

@end
