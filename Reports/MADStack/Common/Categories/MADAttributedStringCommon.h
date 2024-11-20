//
//  MADAttributedStringCommon.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_NSAttributedString_Common_h
#define MAD_Designer_NSAttributedString_Common_h

#import <Foundation/NSAttributedString.h>

@interface MADAttributedStringCommon : NSObject

    + (instancetype)newAttributedStringEDATwitter;
    + (instancetype)newAttributedStringTwitter;
    + (instancetype)newAttributedStringFollowOnTwitter;
    + (instancetype)newAttributedStringTrademarkStatement;

@end

#endif
