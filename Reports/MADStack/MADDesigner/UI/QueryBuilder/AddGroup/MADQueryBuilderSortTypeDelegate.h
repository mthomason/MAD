//
//  MADQueryBuilderSortTypeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryBuilderSortTypeDelegate_h
#define MADQueryBuilderSortTypeDelegate_h

#import <MAD/MADSortOrder.h>

@class MTQueryBuilderSortTypeViewController;

@protocol MADQueryBuilderSortTypeDelegate
    - (void)uITableViewControllerSortTypeDidFinish:(MTQueryBuilderSortTypeViewController *)controller;
    - (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType;
@end

#endif /* MADQueryBuilderSortTypeDelegate_h */
