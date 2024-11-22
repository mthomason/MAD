//
//  MADQueryVisualizationSchemaPresentationController.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/8/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADQueryVisualizationSchemaPresentationController_h
#define MAD_Designer_MADQueryVisualizationSchemaPresentationController_h

#import <UIKit/UIPresentationController.h>

@protocol MADQueryVisualizationSchemaPresentationDelegate <NSObject>
	- (CGRect)frameOfItemWithObjectID:(int64_t)objectID;
@end

@interface MADQueryVisualizationSchemaPresentationController : UIPresentationController

	- (instancetype)initWithObjectID:(int64_t)objectID
			 presentedViewController:(UIViewController *)presentedViewController
			presentingViewController:(UIViewController *)presentingViewController;

	@property (nonatomic, weak) id <MADQueryVisualizationSchemaPresentationDelegate> delegatePresentation;

@end

#endif
