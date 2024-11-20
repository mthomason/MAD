//
//  MADOperationPromptErrorProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/11/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADOperationPromptErrorProtocol_h
#define MADOperationPromptErrorProtocol_h

#import <Foundation/NSObject.h>

@class NSError;

@protocol MADOperationPromptErrorProtocol <NSObject>

    - (NSError *)error;
    - (BOOL)displayError;
    - (NSUInteger)tag;

@end

#endif /* MADOperationPromptErrorProtocol_h */
