//
//  MADInterfaceControllerKPI.h
//  MAD
//
//  Created by Michael Thomason on 4/5/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADInterfaceControllerKPI_h
#define Reports_MADInterfaceControllerKPI_h

#import <Foundation/WKInterfaceController.h>

@interface MADInterfaceControllerKPI : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupKPI;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *tableKPI;

@end

#endif
