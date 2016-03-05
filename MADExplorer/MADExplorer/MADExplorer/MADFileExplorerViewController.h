//
//  MADFileExplorerViewController.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MADFileManager/MADFileManager.h>
#import <MADExplorer/MADDocumentState.h>
#import "MADCollectionViewLayoutGroupedDelegate.h"
#import "MADSaveFileProtocol.h"

@class MADFileLocationManager, MADOpenDocumentManager;

@protocol MADFileExplorerDelegate <NSObject>

    - (NSURL *)thumbnailUrlForUrl:(NSURL *)fileUrl;
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

    - (NSString *)subtitleForMetadata:(MADMetaData *)metadata;
    @property (readonly) UIManagedDocument *openDocument;

@end
