//
//  UIViewControllerSchemaAddTable.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddTableViewController.h"
#import "RptqDatabaseSchemaTable.h"

@implementation MTQueryBuilderAddTableViewController

@synthesize delegate = _delegate;
@synthesize excludeResults = _excludeResults;

- (void)dealloc {
    [_excludeResults release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellTableName";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier] autorelease];
    }
    
    RptqDatabaseSchemaTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[cell textLabel] setText: [tablea name]];
    [tablea release];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqDatabaseSchemaTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[self delegate] viewControllerSchemaAddTableDidSelectTable: tablea];
    [tablea release];
}

@end