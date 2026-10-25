//
//  UICollectionReusableView+Reuse.h
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_UICollectionReusableView_Reuse_h
#define Reports_UICollectionReusableView_Reuse_h

#import <UIKit/UICollectionViewCell.h>

@interface UICollectionReusableView (Reuse)

+ (NSString *)reuseIdentifier;

@end

#endif
