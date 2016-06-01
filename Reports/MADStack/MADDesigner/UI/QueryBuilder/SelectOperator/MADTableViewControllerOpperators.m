//
//  UITableViewControllerOpperators.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewControllerOpperators.h"
#import "MADTableViewControllerOpperatorsDelegate.h"

#import <MAD/RptqQueryPredicate+Extras.h>

static NSString * const MADIDOperatorEqual                   = @"UITableViewCellPredicateOperatorEqual";
static NSString * const MADIDOperatorNotEqual                = @"UITableViewCellPredicateOperatorNotEqual";
static NSString * const MADIDOperatorGreaterThan             = @"UITableViewCellPredicateOperatorGreaterThan";
static NSString * const MADIDOperatorGreaterThanOrEqualTo    = @"UITableViewCellPredicateOperatorGreaterThanOrEqualTo";
static NSString * const MADIDOperatorLessThanOrEqualTo       = @"UITableViewCellPredicateOperatorLessThanOrEqualTo";
static NSString * const MADIDOperatorLessThan                = @"UITableViewCellPredicateOperatorLessThan";

#define MADPredicateOperatorReuseIds [NSArray arrayWithObjects: @"UITableViewCellPredicateOperatorEqual", @"UITableViewCellPredicateOperatorNotEqual", @"UITableViewCellPredicateOperatorGreaterThan", @"UITableViewCellPredicateOperatorGreaterThanOrEqualTo", @"UITableViewCellPredicateOperatorLessThan", @"UITableViewCellPredicateOperatorLessThanOrEqualTo", nil]

@implementation MADTableViewControllerOpperators

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell __weak *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *reuseIdentifier = cell.reuseIdentifier.copy;
    
    if ([reuseIdentifier isEqualToString: MADIDOperatorEqual]) {
        [self.delegate uITableViewControllerOpperatorsDidSelectOperator: MADPredicateOperatorEqual];
        
    } else if ([reuseIdentifier isEqualToString:MADIDOperatorNotEqual]) {
        [self.delegate uITableViewControllerOpperatorsDidSelectOperator: MADPredicateOperatorNotEqual];
        
    } else if ([reuseIdentifier isEqualToString:MADIDOperatorGreaterThan]) {
        [self.delegate uITableViewControllerOpperatorsDidSelectOperator: MADPredicateOperatorGreaterThan];
        
    } else if ([reuseIdentifier isEqualToString:MADIDOperatorGreaterThanOrEqualTo]) {
        [self.delegate uITableViewControllerOpperatorsDidSelectOperator: MADPredicateOperatorGreaterThanOrEqualTo];
        
    } else if ([reuseIdentifier isEqualToString:MADIDOperatorLessThan]) {
        [self.delegate uITableViewControllerOpperatorsDidSelectOperator: MADPredicateOperatorLessThan];
        
    } else if ([reuseIdentifier isEqualToString:MADIDOperatorLessThanOrEqualTo]) {
        [self.delegate uITableViewControllerOpperatorsDidSelectOperator: MADPredicateOperatorLessThanOrEqualTo];
        
    }
}

@end
