//
//  MADQueryViewDatasourceProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADQueryViewDatasourceProtocol_h
#define MAD_MADQueryViewDatasourceProtocol_h

@protocol MADQueryViewControllerDatasourceProtocol <NSObject>

	- (void)queryDatasource:(NSObject <MADQueryViewControllerDatasourceProtocol> *)datasource
				  tableView:(UITableView *)tableView
				 deleteItem:(NSIndexPath *)item
				fromSection:(MADIdentifierQueryViewSections)section;
	- (void)reloadQueryViewData;

	- (MADocument *)document;

@end

#endif /* MADQueryViewDatasourceProtocol_h */
