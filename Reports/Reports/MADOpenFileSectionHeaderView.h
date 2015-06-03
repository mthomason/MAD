//
//  MADOpenFileSectionHeaderView.h
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADOpenFileSectionHeaderView : UICollectionReusableView

typedef NS_ENUM(NSUInteger, MACloudManagerSection) {
    MACloudManagerSectionLocal = 0,
    MACloudManagerSectionCloud = 1,
};

@property (nonatomic, assign) MACloudManagerSection sectionType;

- (void)startAnimating;
- (void)stopAnimating;

@end
