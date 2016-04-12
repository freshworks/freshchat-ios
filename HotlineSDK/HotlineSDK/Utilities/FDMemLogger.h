//
//  FDMemLogger.h
//  HotlineSDK
//
//  Created by Hrishikesh on 14/04/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef FDMemLogger_h
#define FDMemLogger_h

@interface FDMemLogger : NSObject

-(void)addMessage:(NSString*) message;
-(void)addMessage:(NSString*) message withMethodName:(NSString*) methodName;
-(void)addErrorInfo:(NSDictionary*) dict withMethodName:(NSString*) methodName;
-(void)addErrorInfo:(NSDictionary*) dict;
-(NSString *)toString;
-(void)upload;

@end

#endif /* FDMemLogger_h */
