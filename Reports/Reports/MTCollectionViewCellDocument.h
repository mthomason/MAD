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
#import "MTDocumentCellProtocol.h"

@class MTCollectionViewCellDocument;

@interface MTCollectionViewCellDocument : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *labelTitle;
@property (nonatomic, weak) IBOutlet UIImageView *imagePreview;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, weak) id <MTDocumentCellProtocol> delegate;

- (void)configureCellForUrl:(NSURL *)url;
- (void)loadPreviewImageForUrl:(NSURL *)url;

- (void)normalizeTint;
- (void)performSelectionAnimations;
- (void)performDeselectionAnimations;
- (void)setText:(NSString *)text;

+ (NSDictionary *)attributes;

@end

#endif
