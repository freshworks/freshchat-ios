//
//  FCEventsConstants.h
//  FreshchatSDK
//
//  Created by Harish kumar on 21/11/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#ifndef FCEventsConstants_h
#define FCEventsConstants_h

#define FC_INBOUND_EVENT_DIR_PATH @"Freshchat/InBoundEvents"
#define FC_INBOUND_EVENT_FILE_NAME @"fcEventsDict.plist" // Freshchat/Events/events.plist

#define EVENTS_MAX_ID_VALUE 2000

#define FRESHCHAT_ERROR_EVENT_NAME_EMPTY @"Event name is empty"
#define FRESHCHAT_ERROR_EVENT_NAME_EXCEEDS_LIMIT @"Event name length exceeds limit of %d. Event Name: %@"

#define FRESHCHAT_INVALID_PROPERTY @"fc_error"

#define FRESHCHAT_ERROR_PROPERTY_NAME_EXCEEDS_LIMIT @"%@ name exceeds limit"
#define FRESHCHAT_ERROR_PROPERTY_NAME_EMPTY @"Property name is empty"

#define FRESHCHAT_ERROR_PROPERTY_VALUE_EXCEEDS_LIMIT @"%@ value exceeds limit"
#define FRESHCHAT_ERROR_PROPERTY_VALUE_EMPTY @"Property value is empty for %@"
#define FRESHCHAT_ERROR_PROPERTY_VALUE_UNSUPPORTED @"%@ value is not supported"

#define FRESHCHAT_ERROR_PROPERTY_LIMIT_EXCEEDED @"Properties count has exceeded %d"


#endif /* FCEventsConstants_h */
