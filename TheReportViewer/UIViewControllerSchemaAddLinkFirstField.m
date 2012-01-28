//
//  UIViewControllerSchemaAddLink.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSchemaAddLinkFirstField.h"
#import "RptqTable.h"
#import "RptqQueryTables.h"
#import "RptqQueryFields.h"
#import "UIViewControllerSchemaAddLinkSecondTable.h"

@implementation UIViewControllerSchemaAddLinkFirstField

@synthesize delegate = _delegate;
@synthesize managedDocumentQuery = _managedDocumentQuery;

- (void)dealloc {
    [_managedDocumentQuery release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidUnload {
    [self setManagedDocumentQuery:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showSecondTableInput"]) {
        NSLog(@"Class: %@", NSStringFromClass([[segue destinationViewController] class]));
        if ([[segue destinationViewController] isKindOfClass: [UIViewControllerSchemaAddLinkSecondTable class]]) {
            UIViewControllerSchemaAddLinkSecondTable *vcFf = [segue destinationViewController];
            if (vcFf) {                

                [vcFf setFirstTableName: [self firstTableName]];
                [vcFf setFirstFieldName: [self firstFieldName]];

                [vcFf setManagedDocumentQuery: [self managedDocumentQuery]];
                
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqTable class])];
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES];
                //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTable.name == %@", [self firstTableName]];
                //request.predicate = predicate;
                request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                                      managedObjectContext: [[self fetchedResultsController] managedObjectContext]
                                                                                        sectionNameKeyPath: nil
                                                                                                 cacheName: nil];
                [vcFf setFetchedResultsController: frc];
                
                [frc release];
            }
        }
    }
}
*/

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
    [[cell detailTextLabel] setText: [[field inTable] name]];
    [field release];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    RptqField *field = [[[self fetchedResultsController] objectAtIndexPath: indexPath] retain];
    [[self delegate] viewControllerSchemaAddLinkFirstFieldDidFinishWith: [field name] from:[self managedDocumentQuery]];
    [field release];
}

@end