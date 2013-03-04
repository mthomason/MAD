//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import "RptqTable.h"
#import "RptqField.h"
#import "MTQueryBuilderAddLinkFirstFieldViewController.h"

@implementation MTQueryBuilderAddLinkFirstTableViewController

@synthesize delegate = _delegate;

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
    
    RptqTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[cell textLabel] setText: [tablea name]];
    [[cell detailTextLabel] setText: @""];
    [tablea release];
/*
    switch ([self sectionCounter]) {
        case 0: {
            break;
        }
        case 1: {
            RptqField *field = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
            [[cell textLabel] setText: [field name]];
            [[cell detailTextLabel] setText: [[field inTable] name]];
            [field release];
            break;
        }
        case 2: {
            RptqTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
            [[cell textLabel] setText: [tablea name]];
            [[cell detailTextLabel] setText: @""];
            [tablea release];
            break;
        }
        case 3: {
            RptqField *field = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
            [[cell textLabel] setText: [field name]];
            [[cell detailTextLabel] setText: [[field inTable] name]];
            [field release];
            break;
        }
        default:
            break;
    }
    */
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqTable *tablea = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[self delegate] viewControllerDidFinishWithTable:tablea];
    [tablea release];
}

@end