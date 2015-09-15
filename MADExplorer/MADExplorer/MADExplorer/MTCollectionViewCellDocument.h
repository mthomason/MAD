//
//  MTCollectionViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCollectionViewCellDocument_h
#define Reports_MTCollectionViewCellDocument_h

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MTDocumentCellProtocol.h"

@class MTCollectionViewCellDocument;

@interface MTCollectionViewCellDocument : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *labelTitle;
@property (nonatomic, weak) IBOutlet UILabel *labelTitleSub;
@property (nonatomic, weak) IBOutlet UIImageView *imagePreview;
@property (nonatomic, weak) IBOutlet UIImageView *imageCloudIndicator;
@property (nonatomic, strong) IBOutlet UIProgressView *progressViewDownload;
@property (nonatomic, strong) IBOutlet UIProgressView *progressViewUpload;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, weak) id <MTDocumentCellProtocol, UIGestureRecognizerDelegate> delegate;

+ (UIFont *)CaptionFont;
+ (UIFont *)CaptionFont2;

+ (NSDictionary *)attributesCaption;
+ (NSDictionary *)attributesCaption2;

+ (UIImage *)defaultThumbnail;

- (void)loadPreviewImageForUrl:(NSURL *)url;

- (void)normalizeTint;
- (void)performSelectionAnimations;
- (void)performDeselectionAnimations;
- (void)setText:(NSString *)text;

- (void)updateFont;

@end

#endif
