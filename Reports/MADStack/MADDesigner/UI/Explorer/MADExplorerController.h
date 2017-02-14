//
//  MADFileExplorerViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileExplorerViewController_h
#define Reports_MADFileExplorerViewController_h

#import <UIKit/UICollectionViewController.h>
#import <MADExplorer/MADDocumentCellProtocol.h>

@interface MADExplorerController : UICollectionViewController
    <MADDocumentCellProtocol>

    + (instancetype)newFileExplorerViewController;
    - (void)done:(id)sender;

@end

#endif
