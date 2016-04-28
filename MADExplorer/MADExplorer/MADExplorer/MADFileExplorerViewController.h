//
//  MADFileExplorerViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExplorer_MADFileExplorerViewController_h
#define MADExplorer_MADFileExplorerViewController_h

#import <UIKit/UICollectionViewController.h>
#import <MADFileManager/MADFilesController.h>
#import <MADExplorer/MADDocumentState.h>
#import <MADExplorer/MADCollectionViewLayoutGroupedDelegate.h>
#import <MADExplorer/MADSaveFileProtocol.h>

@class MADMetaData;
@class MADFileLocationManager, MADOpenDocumentManager;
@class UIManagedDocument;

@protocol MADFileExplorerDelegate <NSObject>

    - (NSURL *)newUrlThumbnailForUrl:(NSURL *)fileUrl;
    - (void)editFile:(id)sender;
    - (void)emailFile:(id)sender;
    - (void)renameFile:(id)sender;
    - (void)duplicateFile:(id)sender;

@end

@interface MADFileExplorerViewController : UICollectionViewController
    <MADFilesControllerDelegate,
        MADCollectionViewLayoutFilesDelegate,
        MADSaveFileProtocol>

    @property (nonatomic, weak) id <MADFileExplorerDelegate> fileExplorerDelegate;

    @property (nonatomic, strong) MADFileLocationManager *filesCoordnator;
    @property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;
    @property (nonatomic, strong, readwrite) MADOpenDocumentManager *fileManager;
    @property (nonatomic, assign) MTReportState reportState;

    - (NSString *)copySubtitleForMetadata:(MADMetaData *)metadata;
    @property (readonly) UIManagedDocument *openDocument;

@end

#endif
