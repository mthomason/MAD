//
//  MADQueryViewDatasourceProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADQueryViewDatasourceProtocol_h
#define MAD_MADQueryViewDatasourceProtocol_h

@protocol MADQueryViewControllerDatasourceProtocol <NSObject>

    - (void)deleteItemFromQuerySection:(MADIdentifierQueryViewSections)querySection
                         fromTableView:(UITableView *)tableView
                           atIndexPath:(NSIndexPath *)indexPath;
    - (void)reloadQueryViewData;

    - (MADocument *)document;

@end

#endif /* MADQueryViewDatasourceProtocol_h */
