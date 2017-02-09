//
//  MTViewControllerValueBasedOnField.h
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerValueBasedOnField_h
#define Reports_MTViewControllerValueBasedOnField_h

#import <UIKit/UIViewController.h>

@protocol MTViewControllerValueBasedOnFieldDelegate;

@class NSManagedObjectID, MADocument;

@interface MADViewControllerValueBasedOnField : UIViewController

    @property (nonatomic, weak) id <MTViewControllerValueBasedOnFieldDelegate> enterStringDelegate;
    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, copy) NSManagedObjectID *schemaFieldObjectId;

@end

#endif
