//
//  UITableViewControllerFontSelector.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADFontSelectorViewController.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MAD/MADFonts.h>
#import "MADReportDesignerFontSelectorDelegateProtocol.h"

static inline CGRect frameWithTopGuide(CGRect frame, CGFloat topGuideLength);
static inline CGRect frameWithTopGuide(CGRect frame, CGFloat topGuideLength) {
    return CGRectMake(frame.origin.x,
                      topGuideLength - frame.size.height,
                      frame.size.width,
                      frame.size.height);
}

static inline UIEdgeInsets contentInset(CGFloat topGuideLength, CGFloat bottomGuideLength);
static inline UIEdgeInsets contentInset(CGFloat topGuideLength, CGFloat bottomGuideLength) {
    return UIEdgeInsetsMake(topGuideLength, CGSizeZero.width, bottomGuideLength, CGSizeZero.width);
}

@interface MADFontSelectorViewController()

    @property (nonatomic, assign) BOOL firstTimeViewWillLayoutSubviews;

    @property (nonatomic, strong) NSString *familyName;
    @property (nonatomic, strong) MADFonts *madFonts;

@end

@implementation MADFontSelectorViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self initialize];
    }
    return self;
}

-  (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    MADFonts *fonts = [[MADFonts alloc] init];
    self.madFonts = fonts;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorRed];
    self.navigationController.navigationBar.alpha = 1.0000f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden: NO animated: animated];
    if (self.clearsBackground) {
        self.tableView.backgroundView = nil;
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.navigationController.parentViewController.preferredContentSize = CGSizeMake(320.0000f, 680.0000f);

    UIEdgeInsets safeAreaInsets;
    MADViewSafeAreaInserts(self.view, &safeAreaInsets);
    
    self.navigationController.navigationBar.frame = frameWithTopGuide(self.navigationController.navigationBar.frame, safeAreaInsets.top);
    
    self.tableView.contentInset = contentInset(safeAreaInsets.top, safeAreaInsets.bottom);
    self.tableView.scrollIndicatorInsets = contentInset(safeAreaInsets.top, safeAreaInsets.bottom);
    if (self.firstTimeViewWillLayoutSubviews) {
        self.tableView.contentOffset = CGPointMake(CGPointZero.x, CGPointZero.y - safeAreaInsets.top);
        self.firstTimeViewWillLayoutSubviews = NO;
    }

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

#pragma mark -
#pragma mark Table view datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.madFonts.familyNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellWithIdentifier = @"MADFontSelectorDefaultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier forIndexPath:indexPath];
    
    NSString *familyName = self.madFonts.familyNames[(NSUInteger)indexPath.row];
    cell.textLabel.text = familyName;
    cell.textLabel.font = [UIFont fontWithName: familyName
                                          size: cell.textLabel.font.pointSize];
    cell.accessoryType = [self.familyName isEqualToString:familyName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    for (UITableViewCell *visibleCell in tableView.visibleCells) {
        visibleCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];


    NSString *familyName = self.madFonts.familyNames[(NSUInteger)indexPath.row];
    [self.delegate tableViewControllerDidUpdateFontToFontWithName:familyName];
}

- (void)setSelectedFamilyName:(NSString *)name {
    NSString *familyName = [NSString stringWithString:name];
    self.familyName = familyName;
}

@end
