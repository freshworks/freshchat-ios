//
//  FAOptionsInterface.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hotline.h"

@protocol FAQOptionsInterface <NSObject>

@required

-(void)setFAQOptions:(FAQOptions *)options;

@end
