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

#define HOTLINE_API_UPDATE_SDK_BUILD_NUMBER_PATH @"/app/services/app/v2/%@/user/%@/client"

#define HOTLINE_API_DAU_PATH @"/app/services/app/%@/user/%@/activity"

#define HOTLINE_API_SESSION_PATH @"/app/services/app/%@/user/%@/session"

#define HOTLINE_API_HEARTBEAT_PATH @"/app/services/app/%@/user/%@/heartbeat"

#define HOTLINE_API_UNINSTALLED_PATH @"/app/services/app/%@/user/%@/uninstalled"

#define HOTLINE_API_USER_PROPERTIES_PATH @"/app/services/app/%@/user/%@"

#define HOTLINE_API_CATEGORIES_PATH @"/app/services/app/%@/sdk/faq/v2/category"

#define HOTLINE_API_ARTICLES_PATH @"/app/services/app/%@/sdk/faq/category/%@/article"

#define HOTLINE_API_ARTICLE_VOTE_PATH @"/app/services/app/%@/sdk/faq/v2/category/%@/article/%@"

#define HOTLINE_API_CHANNELS_PATH @"/app/services/app/%@/channel/v2"

#define HOTLINE_API_USER_CONVERSATION_ACTIVITY @"app/services/app/%@/user/%@/conversation/read"

#define HOTLINE_API_UPLOAD_MESSAGE @"app/services/app/%@/user/%@/feedback/message/v2"

#define HOTLINE_API_DOWNLOAD_ALL_MESSAGES_API @"/app/services/app/%@/user/%@/conversation/v2"

#define HOTLINE_API_MARKETING_MESSAGE_STATUS_UPDATE_PATH @"/app/services/app/%@/user/%@/message/marketing/%@/status"

#define FRESHCHAT_API_REMOTE_CONFIG_PREFIX @"%@/"

#define FRESHCHAT_API_REMOTE_CONFIG_PATH @"/app/services/app/config/mobile/%@"

#define HOTLINE_API_CSAT_PATH @"/app/services/app/%@/user/%@/conversation/%@/csat/%@/response"

#define HOTLINE_API_UPLOAD_IMAGE @"app/services/app/%@/user/%@/image"

#define HOTLINE_API_TYPLICAL_REPLY @"app/services/app/%@/channels/response_time"

#define FRESHCHAT_USER_RESTORE_PATH @"/app/services/app/%@/user/restore"

#define FRESHCHAT_API_JWT_VALIDATE @"/app/services/app/webchat/%@/jwt/validate"

#define FRESHCHAT_API_USER_RESTORE_WITH_JWT_PATH @"/app/services/app/%@/user/restore-by-jwt"
