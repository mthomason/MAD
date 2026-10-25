//
//  MADAlertControllerAlertRemovedProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADAlertControllerAlertRemovedProtocol_h
#define MADAlertControllerAlertRemovedProtocol_h

@protocol MADAlertControllerAlertRemovedProtocol <NSObject>

	- (void)alertControllerDidDisappear:(MADAlertController *)alertController;

@end

#endif /* MADAlertControllerAlertRemovedProtocol_h */
