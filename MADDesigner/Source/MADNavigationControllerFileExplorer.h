//
//  MADNavigationControllerFileExplorer.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/19/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADNavigationControllerFileExplorer_h
#define Reports_MADNavigationControllerFileExplorer_h

#import <UIKit/UINavigationController.h>
#import "MADNavigationControllerIdentity.h"

@interface MADNavigationControllerFileExplorer : UINavigationController <MADNavigationControllerIdentify, UINavigationControllerDelegate>

- (void)done:(id)sender;
- (void)done:(id)sender completion:(void (^)(void))completion;

@end

#endif
