//
//  MADQueryBuilderAddLinkJoinTypeDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryBuilderAddLinkJoinTypeDelegate_h
#define MADQueryBuilderAddLinkJoinTypeDelegate_h

#import <MAD/MADQueryLinkType.h>

@class MADocument;

@protocol MADQueryBuilderAddLinkJoinTypeDelegate

    - (MNSLinkType)initalLinktype;
    - (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith: (MNSLinkType)result
                                                        from: (MADocument *)document;

@end


#endif /* MADQueryBuilderAddLinkJoinTypeDelegate_h */
