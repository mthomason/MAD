//
//  MADTextInputController.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/31/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADTextInputController_h
#define MAD_Designer_MADTextInputController_h

#import <Foundation/NSObject.h>

@class MADReportTextRepresentation;

@interface MADTextInputController : NSObject

    @property (nonatomic, weak) MADReportTextRepresentation *textRepresentation;

@end

#endif
