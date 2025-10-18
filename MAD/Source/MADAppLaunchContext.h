//
//  MADAppLaunchContext.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/14/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADAppLaunchContext_h
#define MADDesigner_MADAppLaunchContext_h

#import <Foundation/NSObject.h>

@class NSUserActivity;

@interface MADAppLaunchContext : NSObject

	@property (nonatomic, strong, readonly) NSURL *fileURL;

	/*!
	 * Initializes an \c MADAppLaunchContext instance with the color
	 *      and URL designated by the user activity.
	 *
	 * \param userActivity
	 * The userActivity providing the file URL and list color to launch to.
	 */
	- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity;

	/*!
	 * Initializes an \c MADAppLaunchContext instance with the color and
	 *      URL designated by the lister:// URL.
	 *
	 * \param listerURL
	 * The URL adhering to the lister:// scheme providing the file URL and list color to launch to.
	 */
	- (instancetype)initWithFileURL:(NSURL *)fileURL;

@end

#endif
