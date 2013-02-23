//
//  TaxiListModeViewController.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-20.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaxiListModeViewController : UITableViewController

@property (nonatomic) BOOL isSearch;
@property (strong,nonatomic) NSArray *taxiList;

@end
