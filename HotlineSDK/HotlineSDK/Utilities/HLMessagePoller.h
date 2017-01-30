//
//  HLMessagePoller.h
//  HotlineSDK
//
//  Created by Hrishikesh on 25/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#ifndef HLMessagePoller_h
#define HLMessagePoller_h
#import "HLMessageServices.h"


@interface HLMessagePoller : NSObject

-(instancetype) initWithPollType:(enum MessageFetchType) pollType;
-(void)begin;
-(void)end;
-(void)reset;

@end

#endif /* HLMessagePoller_h */
