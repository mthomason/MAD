//
//  MADQueryViewController+BuilderDelegates.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADQueryViewController_BuilderDelegates_h
#define MAD_MADQueryViewController_BuilderDelegates_h

#import "MADQueryViewController_Private.h"

@interface MADQueryViewController (BuilderDelegates) <MADQueryViewControllerLayoutSectionSelectorProtocol, MADQueryBuilderAddTableDelegate, MADQueryBuilderAddGroupDelegate, MADViewControllerStandardProtocol, MADQueryBuilderLinkBuilderDelegate, MADDesignerSectionLayoutDelegate, MADQueryBuilderPredicateFormatDelegate>

- (void)deleteQueryTableFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (void)deleteQueryLinksFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (void)deleteQueryGroupFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (void)deleteQueryPredicateFromTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;

- (IBAction)displaySQL:(id)sender;
- (void)addTable:(id)sender;
- (void)addLink:(id)sender;
- (void)addPredicate:(id)sender;
- (void)addGroup:(id)sender;

@end

#endif
