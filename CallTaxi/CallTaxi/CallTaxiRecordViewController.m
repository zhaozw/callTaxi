//
//  CallTaxiRecordViewController.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-22.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "CallTaxiRecordViewController.h"
#import "OperateAgreement.h"
#import "Common.h"
@interface CallTaxiRecordViewController ()

@property (nonatomic,strong) NSArray *callTaxiRecordList;

@end

@implementation CallTaxiRecordViewController

@synthesize callTaxiRecordList = _callTaxiRecordList;


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    _callTaxiRecordList = [OperateAgreement getCallTaxiRecord];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.callTaxiRecordList.count == 0)
    {
        return 1;
    }
    return self.callTaxiRecordList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.callTaxiRecordList.count == 0 && indexPath.row == 0)
	{
        NSString *PlaceholderCellIdentifier = @"PlaceholderCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier];
        if (cell == nil)
		{
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:PlaceholderCellIdentifier];
            cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        
		cell.detailTextLabel.text = [NSString stringWithFormat:@"没有招车记录。"];
		
		return cell; //记录为0则直接返回，只显示数据加载中…
    }
    
    
    
    static NSString *CellIdentifier = @"record";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] init];
    }
    
    NSDictionary * recordDic = [self.callTaxiRecordList objectAtIndex:indexPath.row];


    {
        UILabel *licenseplatenumber = (UILabel *)[cell viewWithTag:100];
        UILabel *phoneNumber = (UILabel *)[cell viewWithTag:101];
        UILabel *time = (UILabel *)[cell viewWithTag:102];
        
        licenseplatenumber.text = [NSString stringWithFormat:@"出租车牌照: %@",[recordDic valueForKey:Taxi_Record_TaxiNumber]];
        phoneNumber.text = [NSString stringWithFormat:@"司机号码: %@", [recordDic valueForKey:Taxi_Record_DriverPhoneNumber]];
        time.text = [NSString stringWithFormat:@"招车时间: %@", [recordDic valueForKey:Taxi_Record_Time]];
    }
    
  
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.callTaxiRecordList.count == 0)
        return;
    NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
    
    NSDictionary *recordDic = [self.callTaxiRecordList objectAtIndex:selectedRowIndex.row];
    
    NSString *licenseplateNumber = [recordDic valueForKey:Taxi_Record_TaxiNumber];
    
    
     NSString *info = [NSString stringWithFormat:@"您需要再一次向车牌号为%@的司机招车吗？",licenseplateNumber];
     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:info
                               delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
    
     //alertView.
     alertView.tag = 100;
     [alertView show];
    
//    if (taxiInfo)
//    {
//        [Common makeCall:taxiInfo.phoneNumber];
//        NSData *sendData = [OperateAgreement GetSendTransactionData:taxiInfo.phoneNumber];
//        [self sendData:sendData];
//        [OperateAgreement SaveCallTaxiRecordWhitDriverPhoneNumber:taxiInfo.phoneNumber
//                                            andLicenseplatenumber:taxiInfo.licenseplatenumber];
//    }
    

}

#pragma mark UserPhoneNumber AlertView



- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag ==100 && buttonIndex == 0)
    {
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        NSDictionary *recordDic = [self.callTaxiRecordList objectAtIndex:selectedRowIndex.row];
        NSString *phoneNumber = [recordDic valueForKey:Taxi_Record_DriverPhoneNumber];
        [Common makeCall:phoneNumber];
        [self.tableView deselectRowAtIndexPath:selectedRowIndex animated:YES];
        //占时不记录。
//        NSData *sendData = [OperateAgreement GetSendTransactionData:phoneNumber];
//        [self sendData:sendData];
//        [OperateAgreement SaveCallTaxiRecordWhitDriverPhoneNumber:taxiInfo.phoneNumber
//                                            andLicenseplatenumber:taxiInfo.licenseplatenumber]

    }
    
    
}




@end
