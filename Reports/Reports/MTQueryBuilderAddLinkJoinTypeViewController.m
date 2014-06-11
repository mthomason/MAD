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

#import "MTQueryBuilderAddLinkJoinTypeViewController.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "RptqUserCredentals.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlServer.h"

@interface MTQueryBuilderAddLinkJoinTypeViewController ()

@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellEquiJoin;
@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellNaturalJoin;
@property (nonatomic, strong) IBOutlet UITableViewCell *tableViewCellFullOuterJoin;

@end

@implementation MTQueryBuilderAddLinkJoinTypeViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSManagedObjectContext *managedObjectContext = [[[AppDelegate app] activeDocument] managedObjectContext];

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
    
    id activeDocument = [[AppDelegate app] activeDocument];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeInnerJoin]]) {

        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeInnerJoin from:activeDocument];
        
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeEquiJoin]]) {

        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeEquiJoin from:activeDocument];

    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeNaturalJoin]]) {
    
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeNaturalJoin from:activeDocument];

    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeCrossJoin]]) {
    
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeCrossJoin from:activeDocument];
    
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeLeftOuterJoin]]) {

        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeLeftOuterJoin from:activeDocument];

    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeRightOuterJoin]]) {
    
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeRightOuterJoin from:activeDocument];

    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[RptqQueryLinks ReuseIdForLinkType:MNSLinkTypeFullOuterJoin]]) {

        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeFullOuterJoin from:activeDocument];
    
    }
}

@end
