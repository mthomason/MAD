//
//  MADOpenFileSectionHeaderView.h
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADOpenFileSectionHeaderView_h
#define MADDesigner_MADOpenFileSectionHeaderView_h

#import <UIKit/UICollectionViewCell.h>

typedef NS_ENUM(NSUInteger, MACloudManagerSection) {
    MACloudManagerSectionLocal = 0,
    MACloudManagerSectionCloud = 1,
};

extern NSString * const MADIdentifierOpenFileSectionHeader;

@interface MADOpenFileSectionHeaderView : UICollectionReusableView

    @property (nonatomic, assign) MACloudManagerSection sectionType;

    - (void)startAnimating;
    - (void)stopAnimating;

@end

#endif
