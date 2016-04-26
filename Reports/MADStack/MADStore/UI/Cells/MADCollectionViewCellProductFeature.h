//
//  MADCollectionViewCellProductFeature.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADCollectionViewCellProductFeature_h
#define MAD_Designer_MADCollectionViewCellProductFeature_h

#import <UIKit/UICollectionViewCell.h>

@class UILabel;
@class UITextView;

@interface MADCollectionViewCellProductFeature : UICollectionViewCell

    @property (nonatomic, weak) IBOutlet UIImageView *image;
    @property (nonatomic, weak) IBOutlet UILabel *labelTitle;
    @property (nonatomic, weak) IBOutlet UILabel *labelPrice;
    @property (nonatomic, weak) IBOutlet UITextView *labelDescription;

@end

#endif
