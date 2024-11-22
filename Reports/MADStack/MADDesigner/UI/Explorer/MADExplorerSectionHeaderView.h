//
//  MADExplorerSectionHeaderView.h
//  MAD
//
//  Created by Michael Thomason on 10/8/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADExplorerSectionHeaderView_h
#define MADDesigner_MADExplorerSectionHeaderView_h

#import <UIKit/UICollectionViewCell.h>

typedef NS_ENUM(NSUInteger, MACloudManagerSection) {
	MACloudManagerSectionLocal = 0,
	MACloudManagerSectionCloud = 1,
};

extern NSString * const MADIdentifierOpenFileSectionHeader;

@interface MADExplorerSectionHeaderView : UICollectionReusableView

	@property (nonatomic, assign) MACloudManagerSection sectionType;

	- (void)startAnimating;
	- (void)stopAnimating;

@end

#endif
