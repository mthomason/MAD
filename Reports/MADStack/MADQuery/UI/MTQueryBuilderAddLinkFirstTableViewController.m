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

#import "MTQueryBuilderAddLinkFirstTableViewController.h"
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <UIKit/UILabel.h>

@implementation MTQueryBuilderAddLinkFirstTableViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) { }
    return self;
}

#pragma mark - Actions

- (IBAction)done:(id)sender { }

#pragma mark -
#pragma mark Table View Data Source Protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCellFirstTable";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    
    RptqQueryTable *tablea = [self.fetchedResultsController objectAtIndexPath: indexPath];
    cell.textLabel.text = tablea.alias;
    cell.detailTextLabel.text = @"";

    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RptqQueryTable *tablea = [self.fetchedResultsController objectAtIndexPath: indexPath];
    [self.delegate viewControllerDidFinishWithTable:tablea];
}

@end
