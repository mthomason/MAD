//
//  UITableViewControllerPredicateFormat.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerPredicateFormat.h"
#import "UITableViewcontrollerSchemaAddPredicate.h"

@implementation UITableViewControllerPredicateFormat

@synthesize addPredicateDelegate = _addPredicateDelegate;

- (void)dealloc {
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showAddPredicateFormatFieldOperatorValue"]) {
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerSchemaAddPredicate class]]) {
            UITableViewControllerSchemaAddPredicate *tvcSC = [[segue destinationViewController] retain];
            [tvcSC setDelegate:self];
            [tvcSC release];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateFormatFieldOperatorField"]) {
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerSchemaAddPredicate class]]) {
            UITableViewControllerSchemaAddPredicate *tvcSC = [[segue destinationViewController] retain];
            [tvcSC setDelegate:self];
            [tvcSC release];        }
    }
}

- (void)uITableViewControllerSchemaAddPredicateDidFinish:(UITableViewControllerSchemaAddPredicate *)controller {
    [[self addPredicateDelegate] addPredicateDidCancel: self];
}

- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate {
    [[self addPredicateDelegate] addRptqPredicate: predicate];
}

- (void)uITableViewControllerSchemaAddPredicateWithLeft:(NSString *)leftField comparson:(MNSPredicateOperator)comparsonOperator andRightValue:(NSString *)rightValue {
    [[self addPredicateDelegate] addPredicateWithLeft:leftField comparson:comparsonOperator andRightValue:rightValue];
}


#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)done:(id)sender {
    [[self addPredicateDelegate] addPredicateDidCancel: self];
}
@end