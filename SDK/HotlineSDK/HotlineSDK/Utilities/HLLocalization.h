//
//  HLLocalization.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#ifndef HLLocalization_h
#define HLLocalization_h

//Localization Helper Macro
#define HLLocalizedString(name) NSLocalizedStringFromTable(name, @"HLLocalizable", nil)


//Keys to lookup in HLLocalizable.strings
#define LOC_CONTACT_US_BUTTON_TEXT @"contact_us_button_text"

#define LOC_FAQ_CLOSE_BUTTON_TEXT @"faq_close_button_text"
#define LOC_FAQ_TITLE_TEXT @"faq_title_text"

#define LOC_SEARCH_PLACEHOLDER_TEXT @"search_placeholder_text"

#define LOC_CHANNELS_TITLE_TEXT @"channels_title_text"
#define LOC_CHANNELS_CLOSE_BUTTON_TEXT @"channels_close_button_text"

#define LOC_AUDIO_MSG_TITLE @"audio_message_title"
#define LOC_PICTURE_MSG_TITLE @"picture_message_title"

#define LOC_IMAGE_ATTACHMENT_OPTIONS @"image_attachment_options"
#define LOC_IMAGE_ATTACHMENT_CANCEL_BUTTON_TEXT @"image_attachment_cancel_button_text"
#define LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT @"image_attachment_select_existing_image"
#define LOC_IMAGE_ATTACHMENT_NEW_IMAGE_BUTTON_TEXT @"image_attachment_select_new_image"

#define LOC_CAMERA_UNAVAILABLE_TITLE @"camera_unavailable_title"
#define LOC_CAMERA_UNAVAILABLE_DESCRIPTION @"camera_unavailable_description"
#define LOC_CAMERA_UNAVAILABLE_OK_BUTTON @"camera_unavailable_ok_button_text"

#define LOC_SEND_BUTTON_TEXT @"send_button_text"

#define LOC_ARTICLE_VOTE_PROMPT_PARTIAL @"article_vote_prompt"
#define LOC_THANK_YOU_PROMPT_PARTIAL @"thank_you_prompt"
#define LOC_BUTTON_TEXT_PARTIAL @"_%@_button_text"
#define LOC_TEXT_PARTIAL @"_text"

#endif /* HLLocalization_h */
