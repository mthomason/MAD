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

@interface MADOpenFileViewController : UICollectionViewController
    <MADFilesControllerDelegate,
        MADCollectionViewLayoutFilesDelegate,
        MADSaveFileProtocol>

    @property (nonatomic, assign) MTReportState reportState;
    @property (nonatomic, strong) MADFileLocationManager *filesCoordnator;
    @property (nonatomic, strong, readwrite) MADOpenDocumentManager *fileManager;

    - (NSString *)copySubtitleForMetadata:(MADMetaData *)metadata;

    @property (readonly) __kindof UIManagedDocument *openDocument;

    @property (nonatomic, weak) id <MADOpenFileViewControllerDelegate> openFileDelegate;

    - (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)visible
                                                 animated:(BOOL)animated;


    - (IBAction)done:(id)sender;
    - (IBAction)edit:(id)sender;

    - (void)getUserCloudPrefs;
    - (void)reenable;

@end

#endif
