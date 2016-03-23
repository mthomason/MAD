//
//  MADAlertController.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MADAlertControllerAlertRemovedProtocol;

@interface MADAlertController : UIAlertController

    @property (nonatomic, weak) id <MADAlertControllerAlertRemovedProtocol> madAlertControllerAlertRemovedDelegate;

@end

@protocol MADAlertControllerAlertRemovedProtocol <NSObject>

- (void)alertControllerDidDisappear:(MADAlertController *)alertController;

@end
