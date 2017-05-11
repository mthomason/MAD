//
//  UIViewControllerSchemaAddTable.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderAddTableViewController.h"
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSExpressionDescription.h>
#import <UIKit/UILabel.h>
#import <MAD/RptqDatabaseSchemaTable.h>

@implementation MADQueryBuilderAddTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (NSFetchedResultsController *)fetchedResultsController {
    NSManagedObjectContext *managedObjectContext;
    if (_fetchedResultsController == nil && ((managedObjectContext = _managedObjectContext)) != nil) {
        NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
        NSFetchRequest *request;
        NSSortDescriptor *sort;
        request = [NSFetchRequest fetchRequestWithEntityName: entityName];
        
        NSUInteger expressionCount = 2;
        NSExpressionDescription *expressionDescription[expressionCount];
        
        NSString *keySelf = NSStringFromSelector(@selector(self));
        NSString *keyName = NSStringFromSelector(@selector(name));
        
        NSString *keys[] = {
            keySelf,
            keyName,
        };
        
        NSExpression *expressions[] = {
            [NSExpression expressionForEvaluatedObject],
            [NSExpression expressionForKeyPath: keyName],
        };
        
        NSAttributeType types[] = {
            NSObjectIDAttributeType,
            NSStringAttributeType,
        };
        
        for (NSUInteger i=0; i<expressionCount; i++) {
            expressionDescription[i] = [[NSExpressionDescription alloc] init];
            expressionDescription[i].name = keys[i].copy;
            expressionDescription[i].expression = expressions[i];
            expressionDescription[i].expressionResultType = types[i];
        }
        
        NSArray *propertiesToFetch;
        propertiesToFetch = [[NSArray alloc] initWithObjects: expressionDescription
                                                       count: (NSUInteger)expressionCount];
        
        request.propertiesToFetch = propertiesToFetch;
        request.resultType = NSDictionaryResultType;
        
        sort = [NSSortDescriptor sortDescriptorWithKey: keyName
                                             ascending: YES];
        
        request.sortDescriptors = [[NSArray alloc] initWithObjects:sort, nil];
        
        NSFetchedResultsController *fetchedResultsController;
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
                                                                       managedObjectContext: managedObjectContext
                                                                         sectionNameKeyPath: nil
                                                                                  cacheName: nil];
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Error: (%@, %@)", error.localizedDescription, error.localizedFailureReason);
        }
        
        for (NSUInteger i=0; i<expressionCount; i++) {
            expressionDescription[i] = nil;
            keys[i] = nil;
            expressions[i] = nil;
        }
        
        fetchedResultsController.delegate = self;
        _fetchedResultsController = fetchedResultsController;
    }
    return _fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidFinish: self];
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MADIdentifierTableViewCellAddTable";
    static NSString *keyName;
    if (keyName == nil) keyName = NSStringFromSelector(@selector(name));
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    NSDictionary *result = [self.fetchedResultsController objectAtIndexPath: indexPath];
    NSString *name = result[keyName];
    cell.textLabel.text = name.copy;
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *keySelf = NSStringFromSelector(@selector(self));
    NSDictionary *result = [self.fetchedResultsController objectAtIndexPath: indexPath];
    NSManagedObjectID *objectID = result[keySelf];
    [self.delegate viewController: self addedTableWithID: objectID];
}

@end
