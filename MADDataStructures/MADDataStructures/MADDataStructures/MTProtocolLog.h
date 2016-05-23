//
//  MTProtocolLog.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_DataStructures_MTProtocolLog_h
#define MAD_DataStructures_MTProtocolLog_h

@protocol MTProtocolLog <NSObject>
@required

    - (NSString *)toString;
    - (NSString *)toStringDebug;
    - (NSString *)toStringHumanReadable;

@optional

    - (NSString *)toStringExpressive;
    - (NSString *)toStringSymbolic;
    - (NSString *)toStringName;
    - (NSAttributedString *)toAttributedString;

@end

#endif
