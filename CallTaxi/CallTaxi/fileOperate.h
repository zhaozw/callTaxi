//
//  fileOperate.h
//  smarttraffic
//
//  Created by otech on 12-12-19.
//  Copyright (c) 2012年 zhangzhb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface fileOperate : NSObject

-(BOOL)saveFile:(NSString*)filePath withAppendString:(NSString*)str;
-(NSString *)loadFile:(NSString*)filePath;
-(NSString*)getFilePath:(NSString*)fileName;
-(void)deleteFile:(NSString*)filePath;
@end
