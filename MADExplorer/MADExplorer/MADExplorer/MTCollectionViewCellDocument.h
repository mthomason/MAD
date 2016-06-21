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

@protocol MTDocumentCellProtocol;
@protocol UIGestureRecognizerDelegate;

@class MADCollectionViewCellDocument;
@class UILabel;
@class UIActivityIndicatorView;
@class UIProgressView;

@interface MADCollectionViewCellDocument : UICollectionViewCell

    @property (nonatomic, weak) IBOutlet UILabel *labelTitle;
    @property (nonatomic, weak) IBOutlet UILabel *labelTitleSub;
    @property (nonatomic, weak) IBOutlet UIImageView *imagePreview;
    @property (nonatomic, weak) IBOutlet UIImageView *imageCloudIndicator;

    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewDownload;
    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewUpload;

    @property (nonatomic, weak, readonly) UIActivityIndicatorView *activityIndicator;

    @property (nonatomic, weak) id <MTDocumentCellProtocol, UIGestureRecognizerDelegate> delegate;

    + (UIImage *)newDefaultThumbnail;

    - (void)normalizeTint;
    - (void)performSelectionAnimations;
    - (void)performDeselectionAnimations;
    - (void)setText:(NSString *)text;

    - (void)updateFont;

    - (void)startWobble;
    - (void)stopWobble;

    - (void)setUploadingActive:(BOOL)active
                       percent:(double)percent;

    - (void)setDownloadingActive:(BOOL)active
                         percent:(double)percent;

@end

#endif
