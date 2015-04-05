//
//  MADInterfaceControllerKPI.m
//  MAD
//
//  Created by Michael Thomason on 4/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInterfaceControllerKPI.h"


@interface MADInterfaceControllerKPI()

@end


@implementation MADInterfaceControllerKPI

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    NSLog(@"%@", context);
    //AAPLListInfo *listInfo = context;
    //self.listDocument = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL];
    
    //[self setTitle:listInfo.name];
    //[self setUpInterfaceTable];
    
    // Configure interface objects here.
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



