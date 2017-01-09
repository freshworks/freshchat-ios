//
//  HLConstants.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 24/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//
#include "HLVersionConstants.h"

#ifndef HLConstants_h
#define HLConstants_h

#ifdef DEBUG
#define SOLUTIONS_FETCH_INTERVAL 5
#define CHANNELS_FETCH_INTERVAL 5
#define MESSAGES_FETCH_INTERVAL 5
#else
#define SOLUTIONS_FETCH_INTERVAL 60
#define CHANNELS_FETCH_INTERVAL 60
#define MESSAGES_FETCH_INTERVAL 60
#endif

#define DAU_UPDATE_INTERVAL 600 // 10 mins
#define KONOTOR_REFRESHINDICATOR_TAG 80
#define KONOTOR_MESSAGESPERPAGE 25

#define ON_CHAT_SCREEN_POLL_INTERVAL 15
#define OFF_CHAT_SCREEN_POLL_INTERVAL 120

#define EVENTS_UPLOAD_INTERVAL 15

#endif
