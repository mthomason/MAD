//
//  UITableViewControllerOpperators.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewControllerOpperators.h"
#import "MADTableViewControllerOpperatorsDelegate.h"

#import <MAD/RptqQueryPredicate+Extras.h>

@implementation MADTableViewControllerOpperators

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MADIDOperatorEqual                   = @"UITableViewCellPredicateOperatorEqual";
	static NSString *MADIDOperatorNotEqual                = @"UITableViewCellPredicateOperatorNotEqual";
	static NSString *MADIDOperatorGreaterThan             = @"UITableViewCellPredicateOperatorGreaterThan";
	static NSString *MADIDOperatorGreaterThanOrEqualTo    = @"UITableViewCellPredicateOperatorGreaterThanOrEqualTo";
	static NSString *MADIDOperatorLessThanOrEqualTo       = @"UITableViewCellPredicateOperatorLessThanOrEqualTo";
	static NSString *MADIDOperatorLessThan                = @"UITableViewCellPredicateOperatorLessThan";

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UITableViewCell __weak *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	NSString *reuseIdentifier = [cell.reuseIdentifier copy];
	
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
