//
//  MTViewControllerValueBasedOnField.h
//  Reports
//
//  Created by Michael Thomason on 5/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RptqDatabaseSchemaField+Extras.h"
#import "MTApplicaitonInstance.h"
#import "MTDatabase.h"
#import "RptqDocument+Extras.h"

@protocol MTViewControllerValueBasedOnFieldDelegate
- (void)enterStringDidFinishWithString:(NSString *)userInput;
@end

@interface MTViewControllerValueBasedOnField : UIViewController
    <UITableViewDataSource, UITableViewDelegate,
        UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, assign) IBOutlet id <MTViewControllerValueBasedOnFieldDelegate> enterStringDelegate;
//@property (nonatomic, retain) MTApplicaitonInstance *applicationInstance;
@property (nonatomic, retain) NSManagedObjectID *schemaFieldObjectId;

@end
