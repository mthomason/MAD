//
//  MADModelIDProtocol.h
//  MAD
//
//  Created by Michael on 6/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Identity for the read-model: an int64 identifier that is the store row's own.
//

#ifndef MADModelIDProtocol_h
#define MADModelIDProtocol_h

@protocol MADModelIDProtocol <NSObject>
@property (nonatomic, readonly) int64_t identifier;
@end

#endif /* MADModelIDProtocol_h */
