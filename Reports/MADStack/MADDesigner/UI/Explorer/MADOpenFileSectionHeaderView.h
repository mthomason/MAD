//
//  MADOpenFileSectionHeaderView.h
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

typedef NS_ENUM(NSUInteger, MACloudManagerSection) {
    MACloudManagerSectionLocal = 0,
    MACloudManagerSectionCloud = 1,
};

@interface MADOpenFileSectionHeaderView : UICollectionReusableView

@property (nonatomic, assign) MACloudManagerSection sectionType;

- (void)startAnimating;
- (void)stopAnimating;

@end
