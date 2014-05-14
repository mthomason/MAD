//
//  MTViewControllerValueBasedOnField.h
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewControllerValueBasedOnField_h
#define Reports_MTViewControllerValueBasedOnField_h

#import <UIKit/UIKit.h>

@class NSManagedObjectID;

@protocol MTViewControllerValueBasedOnFieldDelegate
- (void)enterStringDidFinishWithString:(NSString *)userInput;
@end

@interface MTViewControllerValueBasedOnField : UIViewController
    <UITableViewDataSource, UITableViewDelegate,
        UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet id <MTViewControllerValueBasedOnFieldDelegate> enterStringDelegate;
@property (nonatomic, strong) NSManagedObjectID *schemaFieldObjectId;

@end

#endif
