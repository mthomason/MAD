//
//  MTCollectionViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCollectionViewCellDocument_h
#define Reports_MTCollectionViewCellDocument_h

#import <UIKit/UICollectionViewCell.h>
#import <UIKit/UIGestureRecognizer.h>
#import "MTDocumentCellProtocol.h"

@class MTCollectionViewCellDocument;
@class UILabel, UIActivityIndicatorView, UIProgressView;

@interface MTCollectionViewCellDocument : UICollectionViewCell

    @property (nonatomic, weak) IBOutlet UILabel *labelTitle;
    @property (nonatomic, weak) IBOutlet UILabel *labelTitleSub;
    @property (nonatomic, weak) IBOutlet UIImageView *imagePreview;
    @property (nonatomic, weak) IBOutlet UIImageView *imageCloudIndicator;
    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewDownload;
    @property (nonatomic, weak) IBOutlet UIProgressView *progressViewUpload;

    @property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;

    @property (nonatomic, weak) id <MTDocumentCellProtocol, UIGestureRecognizerDelegate> delegate;

    + (UIFont *)newCaptionFont;
    + (UIFont *)newCaptionFont2;

    + (NSDictionary *)newAttributesCaption;
    + (NSDictionary *)newAttributesCaption2;

    + (UIImage *)newDefaultThumbnail;

    - (void)normalizeTint;
    - (void)performSelectionAnimations;
    - (void)performDeselectionAnimations;
    - (void)setText:(NSString *)text;

    - (void)updateFont;

    - (void)startWobble;
    - (void)stopWobble;

@end

#endif
