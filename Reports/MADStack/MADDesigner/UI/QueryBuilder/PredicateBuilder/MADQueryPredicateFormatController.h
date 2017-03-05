//
//  MADQueryPredicateFormatController.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryPredicateFormatController_h
#define Reports_MADQueryPredicateFormatController_h

#import "MADQueryAddPredicateController.h"
#import "MADViewControllerStandardProtocol.h"
#import "MADQueryBuilderAddPredicateDelegate.h"

@class MADQueryPredicateFormatController;

@protocol MTQueryBuilderPredicateFormatDelegate <MADViewControllerStandardProtocol>
    - (void)viewController:(MADQueryPredicateFormatController *)controller
       addedQueryPredicate:(RptqQueryPredicate *)predicate;
@end

@interface MADQueryPredicateFormatController : UITableViewController
    <MADViewControllerStandardProtocol,
        MADQueryAddPredicateProtocol>

    @property (nonatomic, weak) id <MTQueryBuilderPredicateFormatDelegate,
                                        MADViewControllerStandardProtocol> delegate;
    @property (nonatomic, weak) MADocument *document;

    - (IBAction)done:(id)sender;

@end

#endif
