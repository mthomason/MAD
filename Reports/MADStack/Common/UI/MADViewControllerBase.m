//
//  MADViewControllerBase.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/6/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

@dynamic tabBarController;

- (void)dealloc { }

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem.titleView sizeToFit];
}

- (void)commonInit {
    self.viewWillLayoutSubviewsCounter = 0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.viewWillLayoutSubviewsCounter++;
}

- (BOOL)firstTimeViewWillLayoutSubviews {
    return self.viewWillLayoutSubviewsCounter == 1;
}
