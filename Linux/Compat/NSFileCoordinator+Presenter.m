//
//  NSFileCoordinator+Presenter.m
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#import "NSFileCoordinator+Presenter.h"

#if !__APPLE__

@implementation NSFileCoordinator (MADCompatPresenter)

- (instancetype)initWithFilePresenter:(id <NSFilePresenter>)filePresenterOrNil {
	(void)filePresenterOrNil;
	return [self init];
}

@end

#endif /* !__APPLE__ */
