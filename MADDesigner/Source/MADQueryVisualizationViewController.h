//
//  MADQueryBuilderAdvancedViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryBuilderVisualizationViewController_h
#define Reports_MTQueryBuilderVisualizationViewController_h

#import "MADViewControllerDocumentProtocol.h"
#import <UIKit/UIViewController.h>

@interface MADQueryVisualizationViewController : UIViewController <MADViewControllerDocumentProtocol>

- (void)redraw:(BOOL)animated;

@end

#endif
