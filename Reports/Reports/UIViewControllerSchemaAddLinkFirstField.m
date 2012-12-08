//
//  UIViewControllerSchemaAddLink.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSchemaAddLinkFirstField.h"
#import "RptqTable.h"
#import "RptqField.h"
#import "UIViewControllerSchemaAddLinkSecondTable.h"

@implementation UIViewControllerSchemaAddLinkFirstField

@synthesize delegate = _delegate;

- (void)dealloc {
    [super dealloc];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    
    RptqField *field = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[cell textLabel] setText: [field name]];
    [[cell detailTextLabel] setText: [field datatype]];
    [field release];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    RptqField *field = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[self delegate] viewControllerSchemaAddLinkFirstFieldDidFinishWith: [field name] from:[UIManagedDocumentReport activeDocument]];
    [field release];
}

@end