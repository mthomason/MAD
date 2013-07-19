//
//  MTLog.h
//  Reports
//
//  Created by Michael Thomason on 7/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//
#ifndef MTDebugMode
#define MTDebugMode
#endif

#ifdef MTDebugMode
    #define MTLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
    #define MTLog( s, ... )
#endif

#ifdef MTDebugMode
    #define MTLogStatic( s, ... ) NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
    #define MTLogStatic( s, ... )
#endif