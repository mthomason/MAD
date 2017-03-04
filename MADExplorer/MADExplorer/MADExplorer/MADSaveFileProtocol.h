//
//  MADSaveFileProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/13/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADExplorer_MADSaveFileProtocol_h
#define MADExplorer_MADSaveFileProtocol_h

@protocol MADSaveFileProtocol <NSObject>
    - (NSURL *)documentDirectory;
@end

#endif /* MADExplorer_MADSaveFileProtocol_h */
