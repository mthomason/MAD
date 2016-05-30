//
//  MADOpenFileViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADOpenFileViewController_h
#define Reports_MADOpenFileViewController_h

#import <UIKit/UICollectionViewController.h>
#import <MADFileManager/MADFilesControllerDelegate.h>
#import <MADExplorer/MADSaveFileProtocol.h>
#import <MADExplorer/MADCollectionViewLayoutGroupedDelegateProtocol.h>
#import <MADExplorer/MADDocumentState.h>

@class UIManagedDocument;
@class MADMetaData;
@class MADFileLocationManager;
@class MADOpenDocumentManager;

@protocol MADOpenFileViewControllerDelegate;

@interface MADFileExplorerViewController : UICollectionViewController
    <MADFilesControllerDelegate,
        MADCollectionViewLayoutFilesDelegate,
        MADSaveFileProtocol>

    - (void)getUserCloudPrefs;

@end

#endif
