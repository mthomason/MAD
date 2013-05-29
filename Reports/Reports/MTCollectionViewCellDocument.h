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

@property (retain, nonatomic) IBOutlet UILabel *labelTitle;
@property (retain, nonatomic) IBOutlet UIImageView *imagePreview;

@property (nonatomic, assign) id <MTDocumentCellProtocol> delegate;

@end

#endif
