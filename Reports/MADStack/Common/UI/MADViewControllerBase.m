//
//  MADViewControllerBase.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/6/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

- (void)dealloc {

}

- (instancetype)init {
    if (self = [super init]) {
        _viewWillLayoutSubviewsCounter = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _viewWillLayoutSubviewsCounter = 0;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _viewWillLayoutSubviewsCounter = 0;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem.titleView sizeToFit];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.viewWillLayoutSubviewsCounter++;
}

- (BOOL)firstTimeViewWillLayoutSubviews {
    return self.viewWillLayoutSubviewsCounter == 1;
}
