//
//  MADCollectionViewCellProductFeature.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADCollectionViewCellProductFeature_h
#define MAD_Designer_MADCollectionViewCellProductFeature_h

#import <UIKit/UICollectionViewCell.h>

@class UILabel, UITextView;

@interface MADCollectionViewCellProductFeature : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *image;
@property (nonatomic, weak) IBOutlet UILabel *labelTitle;
@property (nonatomic, weak) IBOutlet UILabel *labelPrice;
@property (nonatomic, weak) IBOutlet UITextView *labelDescription;

@end

#endif
