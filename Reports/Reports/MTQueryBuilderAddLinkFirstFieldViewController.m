//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddLinkFirstFieldViewController.h"
#import "RptqDatabaseSchemaField+Extras.h"

@implementation MTQueryBuilderAddLinkFirstFieldViewController

- (void)dealloc {
    [super dealloc];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {

}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellFirstField";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: CellIdentifier] autorelease];
    }
    
    RptqDatabaseSchemaField *field = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[cell textLabel] setText: [field name]];
    [[cell detailTextLabel] setText: [field fieldTypeDisplay]];
    [field release];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    RptqQueryField *field = [[self fetchedResultsController] objectAtIndexPath: indexPath];
    [[self delegate] viewControllerSchemaAddLinkFirstFieldDidFinishWith:field];
}

@end
