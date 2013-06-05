//
//  UITableViewControllerPredicateFormat.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderPredicateFormatViewController.h"
#import "MTQueryBuilderAddPredicateViewController.h"

@implementation MTQueryBuilderPredicateFormatViewController

- (void)dealloc {
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showAddPredicateFormatFieldOperatorValue"]) {
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddPredicateViewController class]]) {
            MTQueryBuilderAddPredicateViewController *tvcSC = [[segue destinationViewController] retain];
            [tvcSC setDelegate:self];
            [tvcSC release];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateFormatFieldOperatorField"]) {
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderAddPredicateViewController class]]) {
            MTQueryBuilderAddPredicateViewController *tvcSC = [[segue destinationViewController] retain];
            [tvcSC setDelegate:self];
            [tvcSC release];        }
    }
}

- (void)viewControllerDidFinish:(id)sender {
    [[self delegate] viewControllerDidFinish:sender];
}

- (void)viewControllerDidCancel:(id)sender {
    [[self delegate] viewControllerDidCancel:sender];
}

- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate {
    [[self delegate] addQueryPredicate: predicate];
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidCancel: self];
}

@end