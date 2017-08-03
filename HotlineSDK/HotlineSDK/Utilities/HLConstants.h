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

/* Solutions */
#define SOLUTIONS_FETCH_INTERVAL_DEFAULT 86400 * 2
#define SOLUTIONS_FETCH_INTERVAL_ON_SCREEN_LAUNCH 300

/* Channels */
#define CHANNELS_FETCH_INTERVAL_DEFAULT 86400 * 2
#define CHANNELS_FETCH_INTERVAL_ON_SCREEN_LAUNCH 300

/* Messages */
#define MESSAGES_FETCH_INTERVAL_DEFAULT 60
#define MESSAGES_FETCH_INTERVAL_ON_SCREEN_LAUNCH 30

//These values needs to be equal to or less than the poller intervals below
//The poller should smartly manage the backoff.
#define MESSAGES_FETCH_INTERVAL_ON_SCREEN_POLL 10 //when in channel list
#define MESSAGES_FETCH_INTERVAL_OFF_SCREEN_POLL 120

/* Timer Interval */
#define ON_CHAT_SCREEN_POLLER_INTERVAL 10//actual message poll
#define OFF_CHAT_SCREEN_POLLER_INTERVAL 120

/* Others */
#define DAU_UPDATE_INTERVAL 600
#define EVENTS_UPLOAD_INTERVAL 15
#define MAX_DAYS_SINCE_LAST_MESSAGE_FOR_POLL 7

#endif
