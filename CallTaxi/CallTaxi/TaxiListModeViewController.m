//
//  TaxiListModeViewController.m
//  CallTaxi
//
//  Created by Fan Lv on 13-2-20.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import "TaxiListModeViewController.h"
#import "OperateAgreement.h"
#import "AsyncUdpSocket.h"
#import "TaxiInfo.h"
#import "Common.h"

@interface TaxiListModeViewController ()

@property (strong,nonatomic) AsyncUdpSocket *socket;

@end

@implementation TaxiListModeViewController

@synthesize socket = _socket;
@synthesize taxiList = _taxiList;
@synthesize isSearch = _isSearch;

- (AsyncUdpSocket *)socket
{
    if (_socket == nil)
    {
        _socket = [[AsyncUdpSocket alloc] initIPv4];
        _socket.delegate = self;
        _socket.maxReceiveBufferSize = 5000;
        //绑定端口
        //NSError *error = nil;
        // [self.socket bindToPort:UDP_SEND_PORT error:&error];
        [self.socket receiveWithTimeout:-1 tag:0];
    }
    return _socket;
}


- (void)setTaxiList:(NSArray *)taxiList
{
    _taxiList = taxiList;
    [self.tableView reloadData];
}

#pragma mark UDP Delegate


- (void)sendData:(NSData * )data
{
    if ([OperateAgreement UserPhoneNumber].length == 0)
    {        
        NSLog(@"UserPhoneNumber =0");
        return;
    }
    [self.socket sendData:data toHost:[OperateAgreement TaxiServerHost] port:UDP_TAXI_SERVER_PORT  withTimeout:1 tag:0];
    
}

//UDP接收消息
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    //---------Log
    NSString *info = [NSString stringWithFormat:@"host: %@,port : %hu",host,port];
    NSLog(@"%@",info);
    //启动监听下一条消息
    [self.socket receiveWithTimeout:-1 tag:0];
    
    BOOL isMessageStart = NO;
    
    
    NSMutableData *receData = [[NSMutableData alloc] init];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < data.length; i++)
    {
        Byte tmp = -1;
        [data getBytes:&tmp range:NSMakeRange(i, 1)];
        if (tmp == 0x7e)
        {
            isMessageStart = !isMessageStart;
        }
        if (isMessageStart)
        {
            [receData appendBytes:&tmp length:sizeof(Byte)];
        }
        if (isMessageStart == NO && tmp == 0x7e)
        {
            [receData appendBytes:&tmp length:sizeof(Byte)];
            NSData *oneMessage = [receData copy];
            receData.length = 0 ;
            NSData *realOneMessage =[OperateAgreement RestoreReceData:oneMessage];
            [dataArray addObject:realOneMessage];
            
            
        }
    }
    NSData *realData = [dataArray objectAtIndex:0];
    if ([OperateAgreement JudgeisCompleteData:realData])
    {
        NSString *messageID = [OperateAgreement GetMessageIdInMessageHead:realData];
        if([messageID isEqualToString:MESSAGE_ID_UPLoadTrade_REPLY])
        {
            NSLog(@"MESSAGE_ID_UPLoadTrade_REPLY");
        }
    }
    
    return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Message not received for error: %@", error);
    self.socket = nil;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Message not send for error: %@",error);
    self.socket = nil;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"Message send success!");
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock
{
    self.socket = nil;
    NSLog(@"socket closed!");
}



- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    if (self.taxiList.count == 0)
    {
        return 1;
    }
    return self.taxiList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.taxiList.count == 0 && indexPath.row == 0)
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
        NSString *str = @"";
        
        if (self.isSearch)
        {
            str = [NSString stringWithFormat:@"没有搜到出租车。"];
            
        }
        else
        {
            str = [NSString stringWithFormat:@"请先搜索出租车。"];
        }
        
		cell.detailTextLabel.text = str;
		
		return cell; //记录为0则直接返回，只显示数据加载中…
    }
    
    
    
    
    
    static NSString *CellIdentifier = @"taxiCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    TaxiInfo *taxiInfo = [self.taxiList objectAtIndex:indexPath.row];
    
    UILabel *licenseplatenumber = (UILabel *)[cell viewWithTag:100];
    UILabel *phoneNumber = (UILabel *)[cell viewWithTag:101];
    UILabel *distanceFromUser = (UILabel *)[cell viewWithTag:102];

    UILabel *star = (UILabel *)[cell viewWithTag:103];
    UILabel *speed = (UILabel *)[cell viewWithTag:104];

    licenseplatenumber.text = [NSString stringWithFormat:@"出租车牌照：%@",taxiInfo.licenseplatenumber];
    phoneNumber.text = [NSString stringWithFormat:@"司机号码：%@",taxiInfo.phoneNumber];
    star.text = [NSString stringWithFormat:@"出租车星级：%d 星",taxiInfo.star];
    if (taxiInfo.distanceFromUser == 0)
    {
        distanceFromUser.text = @"";
    }
    else
    {
        distanceFromUser.text = [NSString stringWithFormat:@"距离：%d 米",(int)taxiInfo.distanceFromUser];
    }
    speed.text = [NSString stringWithFormat:@"车速：%d KM/H",taxiInfo.speed];

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.taxiList.count == 0) 
        return;
    NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];

    TaxiInfo *taxiInfo = [self.taxiList objectAtIndex:selectedRowIndex.row];
    
    if (taxiInfo)
    {
        [Common makeCall:taxiInfo.phoneNumber];
        NSData *sendData = [OperateAgreement GetSendTransactionData:taxiInfo.phoneNumber];
        [self sendData:sendData];
        [OperateAgreement SaveCallTaxiRecordWhitDriverPhoneNumber:taxiInfo.phoneNumber
                                            andLicenseplatenumber:taxiInfo.licenseplatenumber];
    }

    [self.tableView deselectRowAtIndexPath:selectedRowIndex animated:YES];
}


- (void)viewDidUnload
{
    self.socket = nil;
    [super viewDidUnload];
}

@end
