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
#import <UIKit/UITableView.h>
#import <UIKit/UIPickerView.h>

#import <MAD/MTQuery.h>
#import <MAD/MTKeyChain.h>
#import <MADFoundation/MTDataTable.h>


@class NSManagedObjectID;

@class MADocument;

@protocol MTViewControllerValueBasedOnFieldDelegate
    - (void)enterStringDidFinishWithString:(NSString *)userInput;
@end

@interface MTViewControllerValueBasedOnField : UIViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        UIPickerViewDataSource,
        UIPickerViewDelegate>

    @property (nonatomic, weak) id <MTViewControllerValueBasedOnFieldDelegate> enterStringDelegate;
    @property (nonatomic, weak) MADocument *document;
    @property (nonatomic, copy) NSManagedObjectID *schemaFieldObjectId;

@end

#endif
