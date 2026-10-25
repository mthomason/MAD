//
//  MADSaveFileProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/13/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADExplorer_MADSaveFileProtocol_h
#define MADExplorer_MADSaveFileProtocol_h

#import <Foundation/NSObject.h>

@class NSURL;

@protocol MADSaveFileProtocol <NSObject>
- (NSURL *)documentDirectory;
@end

#endif /* MADExplorer_MADSaveFileProtocol_h */
