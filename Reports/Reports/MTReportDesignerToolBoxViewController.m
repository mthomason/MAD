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
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "UIColor+EverydayApps.h"
#import "MTReportDesignerFontSettingsViewController.h"
#import "MTReportDesignerFontSelectorViewController.h"
#import "MTReportDesignerDocumentObjectFormat.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "MTFont.h"

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

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize { }

- (void)viewDidLoad {
    [super viewDidLoad];

    UIStoryboard *storyboard = [MTApplicationInstance storyboard];

    MTReportDesignerFontSettingsViewController *reportDesignerFontSettingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    [reportDesignerFontSettingsViewController setDelegate:self];
    [self setTableViewControllerTextLayoutSettings:reportDesignerFontSettingsViewController];
    
    MTReportDesignerFontSelectorViewController *reportDesignerFontSelectorViewController = [storyboard instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"];
    [reportDesignerFontSelectorViewController setDelegate:self];
    [self setTableViewControllerFontSelector:reportDesignerFontSelectorViewController];

    UINavigationItem *navigationItem = [[[self navigationBar] items] objectAtIndex:0];
    UIBarButtonItem *leftBarButtonItem = [navigationItem leftBarButtonItem];
    UIBarButtonItem *rightBarButtonItem = [navigationItem rightBarButtonItem];
    UIColor *tintColor = [UIColor tintColorRed];
    [rightBarButtonItem setTintColor:tintColor];
    UISegmentedControl *segmentedControl = (UISegmentedControl *)[leftBarButtonItem customView];
    [segmentedControl setTintColor:[UIColor tintColor2]];
    [segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self setSceneSelector:segmentedControl];
    UITableView *tableView = [[self tableViewControllerTextLayoutSettings] tableView];
    [tableView setBounds: [[self contentView] bounds]];
    [tableView setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, [[self contentView] bounds].size.width, [[self contentView] bounds].size.height)];
    [[self contentView] addSubview:[[self tableViewControllerTextLayoutSettings] view]];
}

- (CGFloat)contentHeight {
    CGFloat newHeight = 320.0000f;
    if ([[self sceneSelector] selectedSegmentIndex] == 0) {
        if ([[[[self navigationBar] items] lastObject]  isEqual:[self navigationItemFontSelector]]) {
            newHeight = 580.0000f;
        }
    } else if ([[self sceneSelector] selectedSegmentIndex] == 1) {
        newHeight = 320.0000f;
    }
    return newHeight;
}

- (void)showToolboxWithObjectIds:(NSSet *)objectIds {
    [self setSelectedObjectIds:objectIds];
    [[self tableViewControllerTextLayoutSettings] setSelectedDocumentObjects:objectIds];
}

- (IBAction)userDidRequestFinish:(id)sender {
    if ([self delegate] != nil) {
        [[self delegate] hideToolbox];
    }
}

- (IBAction)valueChanged:(id)sender {
    [sender setEnabled:NO];
    UIStoryboard *sbFontTableView = [MTApplicationInstance storyboard];

    id newViewController = nil;

    [[[[self navigationBar] items] lastObject] setTitle:@""];
    if ([sender selectedSegmentIndex] == 0) {
    
        //[[[[self navigationBar] items] lastObject] setTitle:NSLocalizedString(@"Style", @"Style")];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerStyle"];
    
        [newViewController setDelegate:self];

    } else if ([sender selectedSegmentIndex] == 1) {
    
        //[[[[self navigationBar] items] lastObject] setTitle:NSLocalizedString(@"Layout", @"Layout")];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerLayout"];
    
        [newViewController setDelegate:self];

    } else if ([sender selectedSegmentIndex] == 2) {
    
        //[[[[self navigationBar] items] lastObject] setTitle:NSLocalizedString(@"Format", @"Format")];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"MTReportDesignerDocumentObjectFormatIdentifier"];

    } else if ([sender selectedSegmentIndex] == 3) {
    
        //[[[[self navigationBar] items] lastObject] setTitle:NSLocalizedString(@"Grouping", @"Grouping")];
        newViewController = [sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewControllerGrouping"];
    
    }
    
    [newViewController setSelectedDocumentObjects:[self selectedObjectIds]];
    
    [[newViewController tableView] setBounds: [[self contentView] bounds]];
    [[newViewController tableView] setFrame: CGRectMake(CGPointZero.x, CGPointZero.y, [[self contentView] bounds].size.width, [[self contentView] bounds].size.height)];

    [UIView animateWithDuration:0.3000f animations:^{

        [[[self tableViewControllerTextLayoutSettings] view] removeFromSuperview];
        [self setTableViewControllerTextLayoutSettings:newViewController];
        [[self contentView] addSubview:[[self tableViewControllerTextLayoutSettings] view]];
    
    } completion:^(BOOL finished) {
    
        [[self delegate] toolboxHeightChanged:[self contentHeight]];
        [sender setEnabled:YES];

    }];
}

#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item {
    [[self delegate] toolboxHeightChanged:[self contentHeight]];
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
    } else if ([item isEqual:[self navigationItemLayout]]) {
    } else if ([item isEqual:[self navigationItemStyle]]) {
    }
    
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item {
    [[self delegate] toolboxHeightChanged:[self contentHeight]];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    BOOL shouldPopItem = NO;
    
    if ([item isEqual:[self navigationItemFontSelector]]) {
        shouldPopItem = YES;
        
        CGRect offScreen = CGRectMake([[[self tableViewControllerFontSelector] tableView] frame].origin.x + [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y,
                                      [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self contentView] bounds]];
        
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerFontSelector] tableView] setFrame: offScreen];
            [[[self tableViewControllerTextLayoutSettings] tableView] setAlpha:1.0000f];
        } completion:^(BOOL finished) {
            [[[self tableViewControllerFontSelector] tableView] removeFromSuperview];
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
        
        
        MTApplicationInstance *applicationInstance = [AppDelegate app];

        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        RptqDocument *document = [reportDocument activeDocument];
        NSManagedObjectContext *managedObjectContext = [document managedObjectContext];
        NSString *frontName = @"";
        for (NSManagedObjectID *objectId in [self selectedObjectIds]) {
            RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
            frontName = [documentObject fontname];
            break;
        }
        [[self tableViewControllerFontSelector] setSelectedFont:[MTFont fontWithFamilyName:frontName]];
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: [[self contentView] bounds]];
        [[[self tableViewControllerFontSelector] tableView] setBounds: [[self contentView] bounds]];

        CGRect newRect = [[[self tableViewControllerFontSelector] tableView] frame];
        CGRect newRectOffscreen = CGRectMake(CGPointZero.x + [[self contentView] bounds].size.width, [[[self tableViewControllerFontSelector] tableView] frame].origin.y, [[[self tableViewControllerFontSelector] tableView] frame].size.width, [[[self tableViewControllerFontSelector] tableView] frame].size.height);
        
        [[[self tableViewControllerFontSelector] tableView] setFrame: newRectOffscreen];
        [[self contentView] addSubview:[[self tableViewControllerFontSelector] tableView]];        
        
        [UIView animateWithDuration:0.3000f animations:^{
            [[[self tableViewControllerTextLayoutSettings] tableView] setAlpha:0.0000f];
            [[[self tableViewControllerFontSelector] tableView] setFrame:newRect];
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
