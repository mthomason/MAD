//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddLinkJoinTypeViewController.h"
#import "AppDelegate.h"

@interface MTQueryBuilderAddLinkJoinTypeViewController ()

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellEquiJoin;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellNaturalJoin;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellFullOuterJoin;

@end

@implementation MTQueryBuilderAddLinkJoinTypeViewController

- (void)dealloc {
    [_tableViewCellEquiJoin release];
    [_tableViewCellNaturalJoin release];
    [_tableViewCellFullOuterJoin release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSManagedObjectContext *managedObjectContext = [[[AppDelegate applicationInstance] activeDocument] managedObjectContext];

    NSArray *connections = [RptqUserCredentals userCredentalsForManagedObjectContext:managedObjectContext];
    RptqUserCredentals *userCredentals = connections[0];
    NSString *databaseDriverType = [userCredentals database_driver_type];

    if ([databaseDriverType isEqualToString:[MTDatabaseMySql identifier]]) {

        [[self tableViewCellEquiJoin] setUserInteractionEnabled:YES];
        [[self tableViewCellEquiJoin] setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[[self tableViewCellEquiJoin] textLabel] setEnabled:YES];
        [[self tableViewCellNaturalJoin] setUserInteractionEnabled:YES];
        [[self tableViewCellNaturalJoin] setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[[self tableViewCellNaturalJoin] textLabel] setEnabled:YES];
        [[self tableViewCellFullOuterJoin] setUserInteractionEnabled:NO];
        [[self tableViewCellFullOuterJoin] setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[[self tableViewCellFullOuterJoin] textLabel] setEnabled:NO];


        
    } else if ([databaseDriverType isEqualToString:[MTDatabaseSqlServer identifier]]) {
        
        [[self tableViewCellEquiJoin] setUserInteractionEnabled:YES];
        [[self tableViewCellEquiJoin] setSelectionStyle:UITableViewCellSelectionStyleGray];
        [[[self tableViewCellEquiJoin] textLabel] setEnabled:YES];
        [[self tableViewCellNaturalJoin] setUserInteractionEnabled:NO];
        [[self tableViewCellNaturalJoin] setSelectionStyle:UITableViewCellSelectionStyleNone];
        [[[self tableViewCellNaturalJoin] textLabel] setEnabled:NO];

    }

}

#pragma mark - Actions

- (IBAction)done:(id)sender {

}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id activeDocument = [[AppDelegate applicationInstance] activeDocument];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex:MNSLinkTypeInnerJoin]]) {

        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeInnerJoin from:activeDocument];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeEquiJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeEquiJoin from:activeDocument];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeNaturalJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeNaturalJoin from:activeDocument];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeCrossJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeCrossJoin from:activeDocument];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeLeftOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeLeftOuterJoin from:activeDocument];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeRightOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeRightOuterJoin from:activeDocument];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeFullOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeFullOuterJoin from:activeDocument];
    }
}

@end
