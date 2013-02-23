//
//  NSString+Help.h
//  CallTaxi
//
//  Created by Fan Lv on 13-2-11.
//  Copyright (c) 2013年 OTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Help)

- (NSData*) hexToBytes;

- (NSString *) stringByPaddingTheLeftToLength:(NSUInteger) newLength withString:(NSString *) padString startingAtIndex:(NSUInteger) padIndex;

@end
