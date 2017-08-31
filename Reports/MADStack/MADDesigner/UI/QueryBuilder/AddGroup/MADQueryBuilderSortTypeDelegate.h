//
//  MADQueryBuilderSortTypeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryBuilderSortTypeDelegate_h
#define MADQueryBuilderSortTypeDelegate_h

#import <MAD/MADSortOrder.h>

@class MADQueryBuilderSortTypeViewController;

@protocol MADQueryBuilderSortTypeDelegate
    - (void)viewController:(UIViewController *)viewController
         didSelectSortType:(MADSortOrder)sortOrderType;
@end

#endif /* MADQueryBuilderSortTypeDelegate_h */
