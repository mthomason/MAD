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

@synthesize addPredicateDelegate = _addPredicateDelegate;

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

- (void)uITableViewControllerSchemaAddPredicateDidFinish:(MTQueryBuilderAddPredicateViewController *)controller {
    [[self addPredicateDelegate] addPredicateDidCancel: self];
}

- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate {
    [[self addPredicateDelegate] addRptqPredicate: predicate];
}

- (IBAction)done:(id)sender {
    [[self addPredicateDelegate] addPredicateDidCancel: self];
}

@end