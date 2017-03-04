//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderAddLinkSecondFieldViewController.h"

#import <UIKit/UIlabel.h>

#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import "MADQueryAddLinkJoinTypeController.h"
#import <CoreData/NSFetchedResultsController.h>

@implementation MTQueryBuilderAddLinkSecondFieldViewController

#pragma mark - View lifecycle

#pragma mark - Actions

- (IBAction)done:(id)sender { }

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellSecondField";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: CellIdentifier];
    }
    
    RptqDatabaseSchemaField *field = [self.fetchedResultsController objectAtIndexPath: indexPath];
    cell.textLabel.text = field.name;
    cell.detailTextLabel.text = [field fieldTypeDisplay];
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    RptqQueryField *field = [self.fetchedResultsController objectAtIndexPath: indexPath];
    [self.delegate viewControllerSchemaAddLinkDidSecondFieldFinishWith: field];
}

@end
