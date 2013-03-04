//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddLinkJoinTypeViewController.h"
#import "RptqTable.h"
#import "AppDelegate.h"

@implementation MTQueryBuilderAddLinkJoinTypeViewController

@synthesize delegate = _delegate;

- (void)dealloc {
    [super dealloc];
}

#pragma mark - View lifecycle

#pragma mark - Actions

- (IBAction)done:(id)sender {

}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex:MNSLinkTypeInnerJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeInnerJoin from:[[AppDelegate activeDocument] document]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeEquiJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeEquiJoin from:[[AppDelegate activeDocument] document]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeNaturalJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeNaturalJoin from:[[AppDelegate activeDocument] document]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeCrossJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeCrossJoin from:[[AppDelegate activeDocument] document]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeLeftOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeLeftOuterJoin from:[[AppDelegate activeDocument] document]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeRightOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeRightOuterJoin from:[[AppDelegate activeDocument] document]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeFullOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeFullOuterJoin from:[[AppDelegate activeDocument] document]];
    }
}

@end