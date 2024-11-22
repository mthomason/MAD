//
//  MADQueryBuilderAddLinkJoinTypeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
