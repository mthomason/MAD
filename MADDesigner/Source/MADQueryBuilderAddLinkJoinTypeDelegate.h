//
//  MADQueryBuilderAddLinkJoinTypeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADQueryBuilderAddLinkJoinTypeDelegate_h
#define MADQueryBuilderAddLinkJoinTypeDelegate_h

#import <MAD/MADQueryLinkType.h>

@class MADocument;

@protocol MADQueryBuilderAddLinkJoinTypeDelegate

- (MADLinkType)initalLinktype;
- (void)viewController:(UIViewController *)viewController addLinkJoinType:(MADLinkType)result;

@end

#endif /* MADQueryBuilderAddLinkJoinTypeDelegate_h */
