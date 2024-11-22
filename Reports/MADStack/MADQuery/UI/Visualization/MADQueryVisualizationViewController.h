//
//  MADQueryBuilderAdvancedViewController.h
//  Reports
//
//  Created by Michael Thomason on 2/14/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryBuilderVisualizationViewController_h
#define Reports_MTQueryBuilderVisualizationViewController_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerDocumentProtocol.h"

@interface MADQueryVisualizationViewController : UIViewController
	<MADViewControllerDocumentProtocol>

	- (void)redraw:(BOOL)animated;

@end

#endif
