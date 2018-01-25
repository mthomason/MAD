//
//  MADCollectionViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADCollectionViewCellDocument_h
#define Reports_MADCollectionViewCellDocument_h

#import <UIKit/UICollectionViewCell.h>

extern NSString * const MADTextNotDownloaded;

@protocol UIGestureRecognizerDelegate;

@class MADMetaData, MADThumbnailView, MADLabelFileExplorerDocumentCellTitle,
       MADLabelFileExplorerDocumentCellSubtitle, UIActivityIndicatorView,
       UIProgressView;

@interface MADCollectionViewCellDocument : UICollectionViewCell

    @property (nonatomic, assign, getter=isWobbling) BOOL wobbling;
    @property (nonatomic, assign, getter=isWorking) BOOL working;

    @property (nonatomic, weak) IBOutlet MADLabelFileExplorerDocumentCellTitle *labelTitle;
    @property (nonatomic, weak) IBOutlet MADLabelFileExplorerDocumentCellSubtitle *labelTitleSub;
    @property (nonatomic, weak) IBOutlet MADThumbnailView *imagePreview;
    @property (nonatomic, weak) IBOutlet UIImageView *imageCloudIndicator;
    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewDownload;
    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewUpload;

    @property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicator;

    @property (nonatomic, weak) id <UIGestureRecognizerDelegate> delegate;

    - (void)handleContentSizeCategoryDidChangeNotification;

    - (void)setUploadingActive:(BOOL)active
                       percent:(double)percent;

    - (void)setDownloadingActive:(BOOL)active
                         percent:(double)percent;

    - (void)updateDisplayForMetaData:(MADMetaData *)metadata editing:(BOOL)editing;

@end

#endif
