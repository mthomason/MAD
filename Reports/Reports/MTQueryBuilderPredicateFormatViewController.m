//
//  UITableViewControllerPredicateFormat.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderPredicateFormatViewController.h"

@implementation MTQueryBuilderPredicateFormatViewController

#pragma mark - View lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
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
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderAddPredicateViewController class]]) {
            MTQueryBuilderAddPredicateViewController *tvcSC = segue.destinationViewController;
            tvcSC.document = self.document;
            tvcSC.delegate = self;
        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateFormatFieldOperatorField"]) {
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderAddPredicateViewController class]]) {
            MTQueryBuilderAddPredicateViewController *tvcSC = segue.destinationViewController;
            tvcSC.document = self.document;
            tvcSC.delegate = self;
        }
    }
}

- (void)viewControllerDidFinish:(id)sender {
    [self.delegate viewControllerDidFinish:sender];
}

- (void)viewControllerDidCancel:(id)sender {
    [self.delegate viewControllerDidCancel:sender];
}

- (void)uITableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate {
    [self.delegate addQueryPredicate: predicate];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

@end
