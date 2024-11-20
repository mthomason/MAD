//
//  MADQueryViewControllerLayoutSectionSelectorProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADQueryViewControllerLayoutSectionSelectorProtocol_h
#define MADQueryViewControllerLayoutSectionSelectorProtocol_h

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol <NSObject>

    - (void)addTable:(id)sender;
    - (void)addLink:(id)sender;
    - (void)addPredicate:(id)sender;
    - (void)addGroup:(id)sender;

@end

#endif /* MADQueryViewControllerLayoutSectionSelectorProtocol_h */
