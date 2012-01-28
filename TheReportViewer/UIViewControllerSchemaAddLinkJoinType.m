//
//  UIViewControllerSchemaAddLink.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSchemaAddLinkJoinType.h"
#import "RptqTable.h"
#import "RptqQueryTables.h"

@implementation UIViewControllerSchemaAddLinkJoinType

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

#pragma mark - Actions

- (IBAction)done:(id)sender {

}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex:MNSLinkTypeInnerJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeInnerJoin from:[self managedDocumentQuery]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeEquiJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeEquiJoin from:[self managedDocumentQuery]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeNaturalJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeNaturalJoin from:[self managedDocumentQuery]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeCrossJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeCrossJoin from:[self managedDocumentQuery]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeLeftOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeLeftOuterJoin from:[self managedDocumentQuery]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeRightOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeRightOuterJoin from:[self managedDocumentQuery]];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSLinkTypeReuseIds objectAtIndex: MNSLinkTypeFullOuterJoin]]) {
        [[self delegate] viewControllerSchemaAddLinkJoinTypeDidFinishWith: MNSLinkTypeFullOuterJoin from:[self managedDocumentQuery]];
    }
}

@end