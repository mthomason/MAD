//
//  MTTableCell.h
//  MAD
//
//  Created by Michael Thomason on 3/25/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTTableCell_Extras_h
#define MAD_MTTableCell_Extras_h

#import <UIKit/UICollectionViewCell.h>

@class UILabel;

@interface MADTableCell : UICollectionViewCell

    @property (nonatomic, strong, readonly) UILabel *label;

@end

#endif
