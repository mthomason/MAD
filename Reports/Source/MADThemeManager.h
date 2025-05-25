//
//  MADThemeManager.h
//  MAD Designer
//
//  Created by Michael on 5/25/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADThemeManager_h
#define Reports_MADThemeManager_h

#import <Foundation/NSObject.h>

@class UINavigationController, UITraitCollection;

NS_ASSUME_NONNULL_BEGIN

@interface MADThemeManager : NSObject

+ (void)applyAppearanceToNavigationController:(UINavigationController *)navigationController
							  traitCollection:(UITraitCollection *)traitCollection;

@end

NS_ASSUME_NONNULL_END

#endif
