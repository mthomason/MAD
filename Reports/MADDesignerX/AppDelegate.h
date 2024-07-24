//
//  AppDelegate.h
//  MAD Designer X
//
//  Created by Michael on 7/23/24.
//  Copyright © 2024 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_AppDelegate_h
#define MAD_Designer_AppDelegate_h

#import <Cocoa/Cocoa.h>
#import <MADFoundation/MADApplicationProtocol.h>

@interface AppDelegate : NSObject
	<NSApplicationDelegate, MADApplicationProtocol>

@property (nullable, nonatomic, strong) NSWindow *window;

@end

#endif
