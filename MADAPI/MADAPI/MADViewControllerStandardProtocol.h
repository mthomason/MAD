//
//  MADViewControllerStandardProtocol.h
//  Reports
//
//  Created by Michael Thomason on 11/1/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADViewControllerStandardProtocol_h
#define MADDesigner_MADViewControllerStandardProtocol_h

@protocol MADViewControllerStandardProtocol
  @optional
    - (void)viewControllerDidFinish:(id)sender;
    - (void)viewControllerDidCancel:(id)sender;
@end

#endif
