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

@property (nonatomic, assign) IBOutlet UILabel *labelTitle;
@property (nonatomic, assign) IBOutlet UIImageView *imagePreview;

@property (nonatomic, assign) id <MTDocumentCellProtocol> delegate;

- (void)dimTint;
- (void)normalizeTint;
- (void)performSelectionAnimations;
- (void)performDeselectionAnimations;
- (void)setText:(NSString *)text;

@end

#endif
