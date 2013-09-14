//
//  MTCollectionViewCellDocument.h
//  Reports
//
//  Created by Michael Thomason on 2/19/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCollectionViewCellDocument_h
#define Reports_MTCollectionViewCellDocument_h

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "UIColor+EverydayApps.h"
#import "MTDocumentCellProtocol.h"

@class MTCollectionViewCellDocument;

@interface MTCollectionViewCellDocument : UICollectionViewCell

@property (nonatomic, retain) IBOutlet UILabel *labelTitle;
@property (nonatomic, retain) IBOutlet UIImageView *imagePreview;

@property (nonatomic, assign) id <MTDocumentCellProtocol> delegate;

- (void)dimTint;
- (void)normalizeTint;

@end

#endif
