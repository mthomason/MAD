//
//  MADQueryViewControllerLayoutSectionSelectorProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADQueryViewControllerLayoutSectionSelectorProtocol_h
#define MADQueryViewControllerLayoutSectionSelectorProtocol_h

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol <NSObject>

- (void)addTable:(id)sender;
- (void)addLink:(id)sender;
- (void)addPredicate:(id)sender;
- (void)addGroup:(id)sender;

@end

#endif
