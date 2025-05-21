//
//  MADDataProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDataProtocol_h
#define MAD_MADDataProtocol_h

@class MADDatabase;

@protocol MADDataProtocol <NSObject>
@required
- (NSArray *)sortDescriptors;
- (MADDatabase *)database;
@end

#endif
