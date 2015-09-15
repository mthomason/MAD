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
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import "MADCollectionViewLayoutGroupedDelegate.h"

@class MADFileLocationManager;

@protocol MADFileExplorerDelegate <NSObject>

- (void)editFile:(id)sender;
- (void)emailFile:(id)sender;
- (void)renameFile:(id)sender;
- (void)duplicateFile:(id)sender;

@end

@interface MADFileExplorerViewController : UICollectionViewController
    <MADFilesControllerDelegate,
        MADCollectionViewLayoutFilesDelegate>

@property (nonatomic, weak) id <MADFileExplorerDelegate> fileExplorerDelegate;

@property (nonatomic, strong) MADFileLocationManager *filesCoordnator;
@property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

- (NSString *)subtitleForMetadata:(MADMetaData *)metadata;

@end
