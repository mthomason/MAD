//
//  NSFileCoordinator+Presenter.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's NSFileCoordinator is built around an initializer that takes the
//  presenter it coordinates for; GNUstep's has no such initializer (its
//  presenters register through +addFilePresenter:).  The frameworks pass nil
//  here anyway -- they coordinate for nobody -- so the shim is the plain
//  init.  Non-Apple only; nothing on Apple sees it.
//
//  The shim also answers GNUstep's -coordinateAccessWithIntents:queue:
//  byAccessor:, whose implementation wraps the accessor as an NSBlockOperation
//  and faults when it runs (SIGSEGV, measured 2026-10-10).  There is no other
//  process or presenter to coordinate with off Apple, so the accessor is
//  called directly on the given queue -- the same answer, through a path that
//  works.
//

#ifndef MADCompat_NSFileCoordinator_Presenter_h
#define MADCompat_NSFileCoordinator_Presenter_h

#if !__APPLE__
#import <Foundation/NSFileCoordinator.h>
#import <Foundation/NSOperation.h>

@protocol NSFilePresenter;
@class NSFileAccessIntent;

@interface NSFileCoordinator (MADCompatPresenter)

- (instancetype)initWithFilePresenter:(id <NSFilePresenter>)filePresenterOrNil;

- (void)coordinateAccessWithIntents:(NSArray<NSFileAccessIntent *> *)intents
							  queue:(NSOperationQueue *)queue
						 byAccessor:(void (^)(NSError *))accessor;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSFileCoordinator_Presenter_h */
