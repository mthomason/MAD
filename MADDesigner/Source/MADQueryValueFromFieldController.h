//
//  MADQueryValueFromFieldController.h
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryValueFromFieldController_h
#define Reports_MADQueryValueFromFieldController_h

#import <UIKit/UIViewController.h>

@protocol MADQueryValueFromFieldControllerDelegate;

@class MADocument;

@interface MADQueryValueFromFieldController : UIViewController

@property (nonatomic, weak) id <MADQueryValueFromFieldControllerDelegate> enterStringDelegate;
@property (nonatomic, weak) MADocument *document;
@property (nonatomic, assign) int64_t schemaFieldObjectId;

@end

#endif
