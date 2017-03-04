//
//  UITableViewControllerPredicateFormat.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryPredicateFormatController.h"
#import <UIKit/UIStoryboardSegue.h>

@implementation MADQueryPredicateFormatController

#pragma mark - View lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    MADocument *document = _document;
    if ([segue.identifier isEqualToString:@"showAddPredicateFormatFieldOperatorValue"]) {
        
        if ([segue.destinationViewController isKindOfClass: [MADQueryBuilderAddPredicateController class]]) {
            MADQueryBuilderAddPredicateController *tvcSC = segue.destinationViewController;
            tvcSC.document = document;
            tvcSC.queryPredicateDelegate = self;
        }
        
    } else if ([segue.identifier isEqualToString:@"showAddPredicateFormatFieldOperatorField"]) {
    
        if ([segue.destinationViewController isKindOfClass: [MADQueryBuilderAddPredicateController class]]) {
            MADQueryBuilderAddPredicateController *tvcSC = segue.destinationViewController;
            tvcSC.document = document;
            tvcSC.queryPredicateDelegate = self;
        }
        
    }
}

- (void)viewControllerDidFinish:(id)sender {
    [self.delegate viewControllerDidFinish:sender];
}

- (void)viewControllerDidCancel:(id)sender {
    [self.delegate viewControllerDidCancel:sender];
}

- (void)tableViewControllerSchemaAddPredicateDidAddPredicate:(RptqQueryPredicate *)predicate {
    [self.delegate addQueryPredicate: predicate];
}

- (IBAction)done:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

@end
