//
//  MTDocumentObjectNewAggregateViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTGroupByViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "RptqQueryField.h"
#import "RptqDocumentObjectAggregate.h"
#import "MTAggregateFunctionsViewController.h"

NSString * const MTSegueAggregateFunctionCount      = @"MTSegueAggregateFunctionCount";
NSString * const MTSegueAggregateFunctionFirst      = @"MTSegueAggregateFunctionFirst";
NSString * const MTSegueAggregateFunctionLast       = @"MTSegueAggregateFunctionLast";
NSString * const MTSegueAggregateFunctionMaximum    = @"MTSegueAggregateFunctionMaximum";
NSString * const MTSegueAggregateFunctionMean       = @"MTSegueAggregateFunctionMean";
NSString * const MTSegueAggregateFunctionMinimum    = @"MTSegueAggregateFunctionMinimum";
NSString * const MTSegueAggregateFunctionSum        = @"MTSegueAggregateFunctionSum";
NSString * const MTSegueAggregateGroupTypeSave      = @"MTSegueAggregateGroupTypeSave";
NSString * const MTSegueAggregateFieldSave          = @"MTSegueAggregateFieldSave";
NSString * const MTIdentifierSegueDocumentObjectEditAggregate = @"MTIdentifierSegueDocumentObjectEditAggregate";
NSString * const MTDocumentObjectNewAggregateViewControllerIdentifier = @"MTDocumentObjectNewAggregateViewControllerIdentifier";
NSString * const MTDocumentObjectNewAggregateNavigationControllerIdentifier = @"MTDocumentObjectNewAggregateNavigationControllerIdentifier";

@interface MTDocumentObjectNewAggregateViewController ()

@property(nonatomic, retain) RptqDocumentObjectAggregate *aggregateDocumentObject;

@end

@implementation MTDocumentObjectNewAggregateViewController

- (void)dealloc {
    [_fieldObject release];
    [_fieldObjectId release];
    [_tableViewCellAggrageFunction release];
    [_tableViewCellAggregateInput release];
    [_tableViewCellAggregateGroupBy release];
    [super dealloc];
}

- (void)updateDisplay {
    
    [self updateField];
    [self updateFunctionType];
    [self updateGroupType];
    
    if ([self delegate]) {

        NSNumber *groupNumber = @([self groupTypeSectionNumber]);
        [[self delegate] didUpdateggregateFunctionWithType:[self aggregateFunctionType]
                                                 inputType:MTAggregateFunctionInputTypeField
                                               inputObject:[self fieldObject]
                                                 groupType:[self aggregateGroupByType]
                                               groupNumber:groupNumber];
    }
    
}

- (void)updateField {

    NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
    NSString *detailtext = [NSString stringWithFormat:formatString, [[self fieldObject] display]];
    [[[self tableViewCellAggregateInput] detailTextLabel] setText:detailtext];
    //[self updateDisplay];

}

- (void)updateFunctionType {

    NSString *functionName = [RptqDocumentObjectAggregate displayStringForType:[self aggregateFunctionType]];
    NSString *detailText = [NSString stringWithFormat:@"%@(x)", functionName];
    [[[self tableViewCellAggrageFunction] detailTextLabel] setText:detailText];
    //[self updateDisplay];

}

- (void)updateGroupType {
    switch ([self aggregateGroupByType]) {
        case MTAggregateGroupByTypeSection: {
            
            NSUInteger group = [self groupTypeSectionNumber];
            NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeSection];
            NSString *detail = [NSString stringWithFormat:format, group];
            [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detail];
            break;
            
        }
        case MTAggregateGroupByTypeReport: {
            
            NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport];
            [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
            break;
            
        }
        case MTAggregateGroupByTypePage: {
            
            NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage];
            [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
            break;
            
        }
        default:
            [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:@""];
            break;
    }
    //[self updateDisplay];

}

- (IBAction)unwindToNewAggregateFunction:(UIStoryboardSegue *)action {

    MTAggregateFunctionType aggregateFunctionType = MTAggregateFunctionTypeNotSet;

    if ([[action identifier] isEqualToString:MTSegueAggregateFunctionCount]) {
    
        aggregateFunctionType = MTAggregateFunctionTypeCount;
        
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionFirst]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeFirst;
    
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionLast]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeLast;
    
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionMaximum]) {
    
        aggregateFunctionType = MTAggregateFunctionTypeMax;
    
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionMean]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeMean;
    
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionMinimum]) {
    
        aggregateFunctionType = MTAggregateFunctionTypeMin;
    
    } else if ([[action identifier] isEqualToString:MTSegueAggregateFunctionSum]) {
        
        aggregateFunctionType = MTAggregateFunctionTypeSum;

    } else if ([[action identifier] isEqualToString:MTSegueAggregateGroupTypeSave]) {

        MTGroupByViewController *groupByViewController = [action sourceViewController];
        [self setAggregateGroupByType:[groupByViewController aggregateGroupType]];
        [self setGroupTypeSectionNumber:[groupByViewController aggregateGroupNumber]];
        
        switch ([self aggregateGroupByType]) {
            case MTAggregateGroupByTypeSection: {
                
                NSUInteger group = [self groupTypeSectionNumber];
                NSString *format = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeSection];
                NSString *detail = [NSString stringWithFormat:format, group];
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detail];
                break;
                
            }
            case MTAggregateGroupByTypeReport: {
                
                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypeReport];
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            case MTAggregateGroupByTypePage: {
                
                NSString *detailText = [RptqDocumentObjectAggregate displayStringForGroupByType: MTAggregateGroupByTypePage];
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:detailText];
                break;
                
            }
            default:
                [[[self tableViewCellAggregateGroupBy] detailTextLabel] setText:@""];
                break;
        }


    } else if ([[action identifier] isEqualToString:MTSegueAggregateFieldSave]) {
        
        MTQueryBuilderChooseFieldViewController *dynamicFieldController = [action sourceViewController];
        RptqQueryField *queryField = [dynamicFieldController queryField];
        [self setFieldObject:queryField];
        [self setFieldObjectId: [queryField objectID]];
        
        NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
        NSString *detailtext = [NSString stringWithFormat:formatString, [queryField display]];
        [[[self tableViewCellAggregateInput] detailTextLabel] setText:detailtext];
        
    }
    
    if (aggregateFunctionType != MTAggregateFunctionTypeNotSet) {
        [self setAggregateFunctionType:aggregateFunctionType];
        NSString *functionName = [RptqDocumentObjectAggregate displayStringForType:aggregateFunctionType];
        NSString *detailText = [NSString stringWithFormat:@"%@(x)", functionName];
        [[[self tableViewCellAggrageFunction] detailTextLabel] setText:detailText];
    }
    
    [self updateDisplay];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer"]) {

    } else if ([[segue identifier] isEqualToString:@"MTSegueAggregateFunctionChooser"]) {
    
        MTAggregateFunctionsViewController *functionChooser = [segue destinationViewController];
        [functionChooser setSelectedFunctionType:[self aggregateFunctionType]];

    } else if ([[segue identifier] isEqualToString:@"MTSegueGroupByPush"]) {

        MTGroupByViewController *groupChooser = [segue destinationViewController];
        [groupChooser selectGroupType:[self aggregateGroupByType] withSectionNumber:[self groupTypeSectionNumber]];
        
    }

}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setEditmode:NO];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setAggregateObjectToEdit:(RptqDocumentObjectAggregate *)aggregateDocumentObject {
    
    [self setAggregateFunctionType:[[aggregateDocumentObject function] integerValue]];
    [self setAggregateGroupByType:[[aggregateDocumentObject groupType] integerValue]];
    [self setGroupTypeSectionNumber:[[aggregateDocumentObject groupNumber] integerValue]];
    [self setFieldObjectId:[[aggregateDocumentObject aggregateField] objectID]];
    [self setFieldObject:[aggregateDocumentObject aggregateField]];
    [self setEditmode:YES];

    [self setAggregateDocumentObject:aggregateDocumentObject];

}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAggregateFunctionType:MTAggregateFunctionTypeSum];
    [self setGroupTypeSectionNumber:0];
    [self setAggregateGroupByType:MTAggregateGroupByTypePage];
    [[self navigationItem] setLeftItemsSupplementBackButton:YES];
    [[self navigationItem] setHidesBackButton:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self editmode]) {
        [self setEditmode:NO];
        [self updateDisplay];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
