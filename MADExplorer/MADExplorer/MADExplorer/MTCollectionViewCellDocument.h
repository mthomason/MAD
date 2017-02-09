//
//  MTCollectionViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADCollectionViewCellDocument_h
#define Reports_MADCollectionViewCellDocument_h

#import <UIKit/UICollectionViewCell.h>

extern NSString * const MADTextNotDownloaded;

@protocol UIGestureRecognizerDelegate;

@class MADMetaData, MADThumbnailView, MADLabelFileExplorerDocumentCellTitle,
       MADLabelFileExplorerDocumentCellSubtitle, UIActivityIndicatorView,
       UIProgressView;

@interface MADStringFormatted : NSObject
    + (NSString *)newStringFormattedSubtitle:(NSString *)status fileSize:(unsigned long long)fileSize;
@end

@interface MADCollectionViewCellDocument : UICollectionViewCell

    @property (nonatomic, assign, getter=isEditing) BOOL editing;

    @property (nonatomic, weak) IBOutlet MADLabelFileExplorerDocumentCellTitle *labelTitle;
    @property (nonatomic, weak) IBOutlet MADLabelFileExplorerDocumentCellSubtitle *labelTitleSub;
    @property (nonatomic, weak) IBOutlet MADThumbnailView *imagePreview;
    @property (nonatomic, weak) IBOutlet UIImageView *imageCloudIndicator;

    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewDownload;
    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewUpload;

    @property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicator;

    @property (nonatomic, weak) id <UIGestureRecognizerDelegate> delegate;

    @property (nonatomic, readonly) NSString *titleLabelText;

    - (void)updateFont;

    - (void)setUploadingActive:(BOOL)active
                       percent:(double)percent;

    - (void)setDownloadingActive:(BOOL)active
                         percent:(double)percent;

    - (void)updateDisplayForMetaData:(MADMetaData *)metadata editing:(BOOL)editing;

@end

#endif
