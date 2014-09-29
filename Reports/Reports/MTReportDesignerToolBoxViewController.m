//
//  UIViewControllerToolBox.m
//  Reports
//
//  Created by Michael Thomason on 1/28/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportDesignerToolBoxViewController.h"

#import "MADocument.h"

#import "MTApplicationInstance.h"
#import "UIColor+EverydayApps.h"
#import "MTReportDesignerFontSettingsViewController.h"
#import "MTReportDesignerFontSelectorViewController.h"
#import "MTReportDesignerDocumentObjectFormat.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "MTFont.h"

const CGFloat MADDefaultsPopooverWidth              = 320.0000f;
const CGFloat MADDefaultsPopooverHeight             = 480.0000f;

@interface MTReportDesignerToolBoxViewController ()
    <UINavigationBarDelegate, MTReportDesignerFontSettingsDelegate,
        MTReportDesignerFontSelectorDelegate>

@property (nonatomic, copy) NSSet *selectedObjectIds;

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UINavigationItem *navigationItemStyle;
@property (nonatomic, weak) IBOutlet UINavigationItem *navigationItemFontSelector;
@property (nonatomic, weak) IBOutlet UINavigationItem *navigationItemLayout;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *sceneSelector;

@property (nonatomic, strong) MTReportDesignerFontSettingsViewController *tableViewControllerTextLayoutSettings;
@property (nonatomic, strong) MTReportDesignerFontSelectorViewController *tableViewControllerFontSelector;
@property (nonatomic, strong) MTReportDesignerDocumentObjectFormat       *tableViewControllerDocumentObjectFormat;

@end

@implementation MTReportDesignerToolBoxViewController

- (void)initialize {
    [self initalizeFontListSettingsTableViewController];
    [self initalizeFontSettingsTableViewController];
    [self initalizeSegmentedControl];
}

- (void)initalizeFontSettingsTableViewController {
    UIStoryboard *storyboard = [MTApplicationInstance storyboard];
    MTReportDesignerFontSettingsViewController *reportDesignerFontSettingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    [reportDesignerFontSettingsViewController setDelegate:self];
    [[reportDesignerFontSettingsViewController tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    reportDesignerFontSettingsViewController.document = self.document;
    [reportDesignerFontSettingsViewController setSelectedDocumentObjects:self.selectedObjectIds];
    [self setTableViewControllerTextLayoutSettings:reportDesignerFontSettingsViewController];
}

- (void)initalizeFontListSettingsTableViewController {
    UIStoryboard *storyboard = [MTApplicationInstance storyboard];
    MTReportDesignerFontSelectorViewController *reportDesignerFontSelectorViewController = [storyboard instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"];
    [reportDesignerFontSelectorViewController setDelegate:self];
    reportDesignerFontSelectorViewController.document = self.document;
    [self setTableViewControllerFontSelector:reportDesignerFontSelectorViewController];
}

- (void)initalizeSegmentedControl {
    
    UINavigationItem *navigationItem = self.navigationBar.items[0];
    navigationItem.rightBarButtonItem.tintColor = [UIColor tintColorRed];

    UISegmentedControl *segmentedControl = (UISegmentedControl *)navigationItem.leftBarButtonItem.customView;
    segmentedControl.tintColor = [UIColor tintColorWhite];
    [segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    self.sceneSelector = segmentedControl;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initialize];
    self.view.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.tableViewControllerTextLayoutSettings.view];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.tableViewControllerTextLayoutSettings.tableView.bounds = self.contentView.bounds;
    self.tableViewControllerTextLayoutSettings.tableView.frame = CGRectMake(CGPointZero.x, CGPointZero.y, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
}

- (CGFloat)contentHeight {
    switch (self.sceneSelector.selectedSegmentIndex) {
        case 0:
            return [self.navigationBar.items.lastObject isEqual:self.navigationItemFontSelector] ? MADDefaultsPopooverHeight : MADDefaultsPopooverWidth;
            break;
        default:
            return MADDefaultsPopooverWidth;
            break;
    }
}

- (void)showToolboxWithObjectIds:(NSSet *)objectIds {
    [self setSelectedObjectIds:objectIds];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:objectIds];
}

- (IBAction)userDidRequestFinish:(id)sender {
    if (self.delegate != nil) {
        [self.delegate hideToolbox];
    }
}

- (IBAction)valueChanged:(id)sender {
    [sender setEnabled:NO];
    UIStoryboard *sbFontTableView = [MTApplicationInstance storyboard];

    id newViewController = nil;

    [[[[self navigationBar] items] lastObject] setTitle:@""];
    if ([sender selectedSegmentIndex] == 0) {
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
        [newViewController setDocument: self.document];
        [newViewController setDelegate:self];

    } else if ([sender selectedSegmentIndex] == 1) {
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerLayout"];
        [newViewController setDocument: self.document];
        [newViewController setDelegate:self];

    } else if ([sender selectedSegmentIndex] == 2) {
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"MTReportDesignerDocumentObjectFormatIdentifier"];
        [(MTReportDesignerDocumentObjectFormat *)newViewController setDocument: self.document];

    } else if ([sender selectedSegmentIndex] == 3) {
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerGrouping"];
        [newViewController setDocument: self.document];
    
    }
    
    [newViewController setSelectedDocumentObjects:[self selectedObjectIds]];
    
    [[newViewController tableView] setBounds: [self.contentView bounds]];
    [[newViewController tableView] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, [self.contentView bounds].size.width, [self.contentView bounds].size.height)];

    __weak MTReportDesignerToolBoxViewController *weakSelf = self;
    [UIView animateWithDuration:0.3000f animations:^{

        [[[weakSelf tableViewControllerTextLayoutSettings] view] removeFromSuperview];
        [weakSelf setTableViewControllerTextLayoutSettings:newViewController];
        [[weakSelf contentView] addSubview:[[weakSelf tableViewControllerTextLayoutSettings] view]];
    
    } completion:^(BOOL finished) {
    
        [[weakSelf delegate] toolboxHeightChanged:[weakSelf contentHeight]];
        [sender setEnabled:YES];

    }];
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    [self.delegate toolboxHeightChanged:[self contentHeight]];
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    [self.delegate toolboxHeightChanged:[self contentHeight]];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL shouldPopItem = NO;
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
        shouldPopItem = YES;
        
        CGRect offScreen = CGRectMake([self.tableViewControllerFontSelector.tableView frame].origin.x + [self.tableViewControllerFontSelector.tableView frame].size.width, [self.tableViewControllerFontSelector.tableView frame].origin.y,
                                      [self.tableViewControllerFontSelector.tableView frame].size.width, [self.tableViewControllerFontSelector.tableView frame].size.height);
        
        [self.tableViewControllerFontSelector.tableView setFrame: [self.contentView bounds]];
        
        __weak MTReportDesignerToolBoxViewController *weakSelf = self;
        [UIView animateWithDuration:0.3000f animations:^{
            [[[weakSelf tableViewControllerFontSelector] tableView] setFrame: offScreen];
            [[[weakSelf tableViewControllerTextLayoutSettings] tableView] setAlpha:1.0000f];
        } completion:^(BOOL finished) {
            [[[weakSelf tableViewControllerFontSelector] tableView] removeFromSuperview];
        }];
    } else if ([item isEqual:[self navigationItemLayout]]) {
        
    } else if ([item isEqual:[self navigationItemStyle]]) {
        
    }
    
    return shouldPopItem;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item {
    BOOL shouldPushItem = NO;
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
    
        shouldPushItem = YES;
        RptqDocument *document = [self.document activeDocumentModel];
        NSManagedObjectContext *managedObjectContext = [document managedObjectContext];
        NSString *frontName = @"";
        for (NSManagedObjectID *objectId in [self selectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject documentObjectForObjectID:objectId
                                                                          managedObjectContext:managedObjectContext];
            frontName = [documentObject fontname];
            break;
        }
        [self.tableViewControllerFontSelector setSelectedFont:[MTFont fontWithFamilyName:frontName]];
        
        [self.tableViewControllerFontSelector.tableView setFrame: [self.contentView bounds]];
        [self.tableViewControllerFontSelector.tableView setBounds: [self.contentView bounds]];

        CGRect newRect = [self.tableViewControllerFontSelector.tableView frame];
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [self.contentView bounds].size.width, [self.tableViewControllerFontSelector.tableView frame].origin.y, [self.tableViewControllerFontSelector.tableView frame].size.width, [self.tableViewControllerFontSelector.tableView frame].size.height);
        
        [self.tableViewControllerFontSelector.tableView setFrame: newRectOffscreen];
        [self.contentView addSubview:self.tableViewControllerFontSelector.tableView];        
        
        __weak MTReportDesignerToolBoxViewController *weakSelf = self;
        [UIView animateWithDuration:0.3000f animations:^{
            [[[weakSelf tableViewControllerTextLayoutSettings] tableView] setAlpha:0.0000f];
            [[[weakSelf tableViewControllerFontSelector] tableView] setFrame:newRect];
        } completion:^(BOOL finished) {
            
        }];
        
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    return shouldPushItem;
}

#pragma mark - UITableViewControllerFontSelectorDelegate

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    CGFloat currentPointSize = [[[[self tableViewControllerTextLayoutSettings] labelFontName] font] pointSize];
    MTFont *font = [[MTFont alloc] initWithFamilyName:fontName andPointSize:currentPointSize];
    [[self tableViewControllerTextLayoutSettings] chooseFont:font];
}

#pragma mark - FontSettingsTableViewControllerDelegate

- (void)fontSettingsTableViewControllerDidSelectFontList:(MTReportDesignerFontSettingsViewController *)controller {
    [[self navigationBar] pushNavigationItem:[self navigationItemFontSelector] animated:YES];
}

@end
