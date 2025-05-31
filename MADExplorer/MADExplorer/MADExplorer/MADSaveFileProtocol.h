//
//  MADSaveFileProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/13/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADExplorer_MADSaveFileProtocol_h
#define MADExplorer_MADSaveFileProtocol_h

#import <Foundation/NSObject.h>

@class NSURL;

@protocol MADSaveFileProtocol <NSObject>
- (NSURL *)documentDirectory;
@end

#endif /* MADExplorer_MADSaveFileProtocol_h */
