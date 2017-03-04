//
//  MADQueryValueFromFieldController.h
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADQueryValueFromFieldController_h
#define Reports_MADQueryValueFromFieldController_h

#import <UIKit/UIViewController.h>

@protocol MADQueryValueFromFieldControllerDelegate;

@class NSManagedObjectID, MADocument;

@interface MADQueryValueFromFieldController : UIViewController

    @property (nonatomic, weak) id <MADQueryValueFromFieldControllerDelegate> enterStringDelegate;
    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, copy) NSManagedObjectID *schemaFieldObjectId;

@end

#endif
