//
//  MADQueryChooseFieldProtocol.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADQueryChooseFieldProtocol_h
#define MAD_MADQueryChooseFieldProtocol_h

@class MADQueryChooseFieldController;
@class RptqQueryField;

@protocol MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
									withFieldID: (int64_t)fieldID;

@end

#endif
