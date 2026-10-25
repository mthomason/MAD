//
//  MADQueryVisualizationSchemaPresentationController.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/8/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADQueryVisualizationSchemaPresentationController_h
#define MAD_Designer_MADQueryVisualizationSchemaPresentationController_h

#import <UIKit/UIPresentationController.h>

@protocol MADQueryVisualizationSchemaPresentationDelegate <NSObject>
	- (CGRect)frameOfItemWithObjectID:(int64_t)objectID;
@end

@interface MADQueryVisualizationSchemaPresentationController : UIPresentationController

@property (nonatomic, weak) id <MADQueryVisualizationSchemaPresentationDelegate> delegatePresentation;

- (instancetype)initWithObjectID:(int64_t)objectID
		 presentedViewController:(UIViewController *)presentedViewController
		presentingViewController:(UIViewController *)presentingViewController;

@end

#endif
