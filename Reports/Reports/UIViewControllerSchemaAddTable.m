//
//  UIViewControllerSchemaAddTable.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSchemaAddTable.h"
#import "RptqTable.h"

@implementation UIViewControllerSchemaAddTable

@synthesize delegate = _delegate;
@synthesize excludeResults = _excludeResults;

- (void)dealloc {
    [_excludeResults release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerSchemaAddTableDidFinish: self];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellTableName";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier] autorelease];
    }
    
    RptqTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[cell textLabel] setText: [tablea name]];
    [tablea release];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[self delegate] viewControllerSchemaAddTableDidSelectTable: tablea];
    [tablea release];
}

@end