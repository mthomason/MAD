//
//  MTTitleView.h
//  Reports
//
//  Created by Michael Thomason on 2/22/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTitleView_h
#define Reports_MTTitleView_h

#import <UIKit/UIView.h>

@class UILabel;

@interface MTTitleView : UIView

    @property (nonatomic, weak) IBOutlet UILabel *label;

@end

typedef NS_ENUM(int16_t, MADTitleViewQueryTableStyle) {
    MADTitleViewQueryTableRoot = 2,
    MADTitleViewQueryTableChild = 3,
};

@interface MADTitleViewQueryTable : MTTitleView

    @property (nonatomic, assign) MADTitleViewQueryTableStyle style;

@end

#endif
