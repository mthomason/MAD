//
//  MADAlertControllerAlertRemovedProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADAlertControllerAlertRemovedProtocol_h
#define MADAlertControllerAlertRemovedProtocol_h

@protocol MADAlertControllerAlertRemovedProtocol <NSObject>

	- (void)alertControllerDidDisappear:(MADAlertController *)alertController;

@end

#endif /* MADAlertControllerAlertRemovedProtocol_h */
