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

#ifndef MADCompat_NSFileCoordinator_Presenter_h
#define MADCompat_NSFileCoordinator_Presenter_h

#if !__APPLE__
#import <Foundation/NSFileCoordinator.h>

@protocol NSFilePresenter;

@interface NSFileCoordinator (MADCompatPresenter)

- (instancetype)initWithFilePresenter:(id <NSFilePresenter>)filePresenterOrNil;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSFileCoordinator_Presenter_h */
