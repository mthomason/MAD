//
//  MADQueryVisualizationSchemaPresentationController.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/8/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MADQueryVisualizationTableDefination, NSManagedObjectID;

@protocol MADQueryVisualizationSchemaPresentationDelegate <NSObject>

    - (MADQueryVisualizationTableDefination *)tableDefinationForObjectID:(NSManagedObjectID *)objectID;
    - (CGRect)frameOfItemWithObjectID:(NSManagedObjectID *)objectID;

@end

@interface MADQueryVisualizationSchemaPresentationController : UIPresentationController

    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
             presentedViewController:(UIViewController *)presentedViewController
            presentingViewController:(UIViewController *)presentingViewController;

    @property (nonatomic, weak) id <MADQueryVisualizationSchemaPresentationDelegate> delegatePresentation;

@end
