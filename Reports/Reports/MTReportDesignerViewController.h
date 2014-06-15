//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerViewController_h
#define Reports_MTReportDesignerViewController_h

typedef void(^MTBlockCompletionSimple)(BOOL finished);
typedef void(^MTBlockCompletionNoReturn)(void);
typedef void (^block_insertObject)(UIStoryboardSegue *);

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
};

typedef NS_ENUM(NSUInteger, MTDirection) {
    MTDirectionNorth,       //60˚-120˚
    MTDirectionNorthWest,   //120˚-150˚
    MTDirectionNorthEast,
    MTDirectionSouth,       //240˚-300˚
    MTDirectionSouthWest,   //210˚-240˚
    MTDirectionSouthEast,
    MTDirectionEast,        //330˚-360˚,0-30˚
    MTDirectionWest,        //210˚-150˚
};

#import <UIKit/UIKit.h>
#import "MUIViewControllerDelegate.h"

@interface MTReportDesignerViewController : UIViewController

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;

- (IBAction)done:(id)sender;
- (IBAction)showObjects:(id)sender;

@end

#endif
