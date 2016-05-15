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
#import <MADFileManager/MADFilesController.h>
#import <MADExplorer/MADDocumentState.h>
#import <MADExplorer/MADCollectionViewLayoutGroupedDelegate.h>
#import <MADExplorer/MADSaveFileProtocol.h>

@class MADMetaData;
@class MADFileLocationManager, MADOpenDocumentManager;
@class UIManagedDocument;

@protocol MADOpenFileViewControllerDelegate <NSObject>

    - (void)openDocumentAtURL:(NSURL *)url;
    - (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType;
    - (NSArray *)supportedUTIs;

@end

@interface MADOpenFileViewController : UICollectionViewController
    <MADFilesControllerDelegate,
        MADCollectionViewLayoutFilesDelegate,
        MADSaveFileProtocol>

    @property (nonatomic, assign) MTReportState reportState;
    @property (nonatomic, strong) MADFileLocationManager *filesCoordnator;
    @property (nonatomic, strong, readwrite) MADOpenDocumentManager *fileManager;

    - (NSString *)copySubtitleForMetadata:(MADMetaData *)metadata;

    @property (readonly) UIManagedDocument *openDocument;

    @property (nonatomic, weak) id <MADOpenFileViewControllerDelegate> openFileDelegate;

    - (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                                 animated:(BOOL)animated;


    - (IBAction)done:(id)sender;
    - (IBAction)edit:(id)sender;

    - (void)getUserCloudPrefs;
    - (void)reenable;

@end

#endif
