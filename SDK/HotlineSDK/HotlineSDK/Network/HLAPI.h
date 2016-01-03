//
//  HLAPI.h
//  HotlineSDK
//
//  Created by AravinthChandran on 9/14/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HTTP_METHOD_GET @"GET"
#define HTTP_METHOD_PUT @"PUT"
#define HTTP_METHOD_POST @"POST"

#define HOTLINE_USER_DOMAIN @"https://%@"

#define HOTLINE_REQUEST_PARAMS @"t=%@"

#define HOTLINE_API_USER_REGISTRATION_PATH @"/app/services/app/%@/user"

#define HOTLINE_API_DEVICE_REGISTRATION_PATH @"/app/services/app/%@/user/%@/notification"

#define HOTLINE_API_CATEGORIES_PATH @"/app/services/app/%@/sdk/faq/category"

#define HOTLINE_API_ARTICLES_PATH @"/app/services/app/%@/sdk/faq/category/%@/article"

#define HOTLINE_API_ARTICLE_VOTE_PATH @"/app/services/app/%@/sdk/faq/category/%@/article/%@"

#define HOTLINE_API_CHANNELS_PATH @"/app/services/app/%@/channel"