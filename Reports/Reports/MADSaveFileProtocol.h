//
//  MADSaveFileProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/13/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADSaveFileProtocol_h
#define MADSaveFileProtocol_h

@protocol MADSaveFileProtocol <NSObject>

    - (NSURL *)documentDirectory;

@end

#endif /* MADSaveFileProtocol_h */
