//
//  MADViewAnimationProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/20/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADViewAnimationProtocol_h
#define MADViewAnimationProtocol_h

@protocol MADViewAnimationProtocol <NSObject>
    - (void)flash:(void (^)(BOOL finished))completion;
@end

#endif /* MADViewAnimationProtocol_h */
