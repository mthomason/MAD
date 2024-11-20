//
//  MADQueryValueFromFieldControllerDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADQueryValueFromFieldControllerDelegate_h
#define MADQueryValueFromFieldControllerDelegate_h

@class NSString;

@protocol MADQueryValueFromFieldControllerDelegate
    - (void)enterStringDidFinishWithString:(NSString *)userInput;
@end

#endif /* MADQueryValueFromFieldControllerDelegate_h */
