//
//  MADInterfaceControllerKPI.h
//  MAD
//
//  Created by Michael Thomason on 4/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface MADInterfaceControllerKPI : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupKPI;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *tableKPI;

@end
