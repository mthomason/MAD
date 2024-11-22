//
//  MADFileInfo.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADFileInfo_h
#define MADDesigner_MADFileInfo_h

#import <Foundation/NSObject.h>

@interface MADFileInfo : NSObject
	<NSCopying>

	@property (nonatomic, copy, readonly) NSURL *URL;
	@property (readonly) NSString *name;

	- (instancetype)initWithURL:(NSURL *)URL;
	- (void)fetchInfoWithCompletionHandler:(void (^)(void))completion;

@end

#endif
