//
//  MADQueryChooseFieldProtocol.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADQueryChooseFieldProtocol_h
#define MAD_MADQueryChooseFieldProtocol_h

@class MADQueryChooseFieldController;
@class RptqQueryField;

@protocol MADQueryChooseFieldProtocol
    - (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
                                          withField: (RptqQueryField *)field;
@end

#endif
