//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import "RptqQueryTable.h"

@implementation MTQueryBuilderAddLinkFirstTableViewController

- (void)dealloc {
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) { }
    return self;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Actions

- (IBAction)done:(id)sender { }

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellFirstTable";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier] autorelease];
    }
    
    RptqQueryTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[cell textLabel] setText: [tablea alias]];
    [[cell detailTextLabel] setText: @""];
    [tablea release];

    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqQueryTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[self delegate] viewControllerDidFinishWithTable:tablea];
    [tablea release];
}

@end
