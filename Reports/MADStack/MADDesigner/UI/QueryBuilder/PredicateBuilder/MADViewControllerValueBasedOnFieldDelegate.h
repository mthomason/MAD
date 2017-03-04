//
//  MADViewControllerValueBasedOnFieldDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADViewControllerValueBasedOnFieldDelegate_h
#define MADViewControllerValueBasedOnFieldDelegate_h

@class NSString;

@protocol MADViewControllerValueBasedOnFieldDelegate
    - (void)enterStringDidFinishWithString:(NSString *)userInput;
@end

#endif /* MADViewControllerValueBasedOnFieldDelegate_h */
