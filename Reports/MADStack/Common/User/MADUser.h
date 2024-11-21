//
//  MADUser.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/22/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

/// This class isn't used in the project right now, but it is a way to create a unique ID for a
/// user.

#ifndef MAD_Designer_MADUser_h
#define MAD_Designer_MADUser_h

#import <Foundation/NSObject.h>

@protocol MADUserDelegate <NSObject>
@end

@interface MADUser : NSObject
@end

#endif
