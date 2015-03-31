//
//  InterfaceController.m
//  MAD Designer WatchKit Extension
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "InterfaceController.h"
#import "UIColor+EverydayApps.h"

@interface InterfaceController()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupTop;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelTop;

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupMiddle;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *tableMain;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonInfo;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonExport;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonMad;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    UIColor *backgroundColor = [UIColor tintColorAnalogous4];
    [self.groupTop setBackgroundColor:backgroundColor];
    
    [self.labelTop setText:@"MAD Viewer"];
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



