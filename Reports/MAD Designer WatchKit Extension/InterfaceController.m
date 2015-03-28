//
//  InterfaceController.m
//  MAD Designer WatchKit Extension
//
//  Created by Michael Thomason on 3/27/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "InterfaceController.h"
#import "MACloudManager.h"

@interface InterfaceController()

@property (weak, nonatomic) IBOutlet WKInterfaceTable *documentInterfaceTable;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    [self.documentInterfaceTable setNumberOfRows:5 withRowType:@""];
    //NSArray *docs = [MACloudManager madDocumentsLocal];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



