//
//  FDAPI.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 20/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDAPI_h
#define FreshdeskSDK_FDAPI_h

/* MOBIHELP API INFO */
#define MOBIHELP_API_ADDITIONAL_PARAMETERS             @"format=json&pt=ios&sv=v%@"

//MOBIHELP_API_HEADERS
#define MOBIHELP_API_HEADER_APPID                      @"X-FD-Mobihelp-AppId"
#define MOBIHELP_API_HEADER_AUTHORIZATION              @"X-FD-Mobihelp-Auth"
#define MOBIHELP_API_HEADER_API_VERSION                @"X-API-Version"

//REGISTRATION_ENDPOINTS
#define MOBIHELP_API_REGISTER_DEVICE                   @"mobihelp/devices/register"
#define MOBIHELP_API_REGISTER_USER                     @"mobihelp/devices/register_user"

//MOIHELP_APP_CONFIG
#define MOBIHELP_API_APP_CONFIG                        @"mobihelp/devices/app_config"

//ARTICLES_ENDPOINTS
#define MOBIHELP_API_ARTICLES                          @"mobihelp/solutions/articles"
#define MOBIHELP_API_ARTICLES_WITH_LAST_UPDATED_TIME   @"mobihelp/solutions/articles?updated_since=%@"

//TICKET_ENDPOINTS
#define MOBIHELP_API_GET_ALL_TICKETS                   @"support/mobihelp/tickets?device_uuid=%@"
#define MOBIHELP_API_GET_TICKET_WITH_ID                @"support/mobihelp/tickets/%@?device_uuid=%@"
#define MOBIHELP_API_CREATE_NEW_TICKET                 @"support/mobihelp/tickets"
#define MOBIHELP_API_CLOSE_TICKET_WITH_ID              @"support/mobihelp/tickets/%@/close"
#define MOBIHELP_API_CREATE_NEW_NOTE_WITH_TICKET_ID    @"support/mobihelp/tickets/%@/notes"

//OTHER_INFO
#define MOBIHELP_API_TICKET_ATTACHMENT_DATA_FIELD     @"helpdesk_ticket[attachments][][resource]"
#define MOBIHELP_API_NOTE_ATTACHMENT_DATA_FIELD       @"helpdesk_note[attachments][resource]"
#define MOBIHELP_API_DEBUG_DATA_FIELD                    @"helpdesk_ticket[mobihelp_ticket_info_attributes][debug_data][resource]"

/* MOBIHELP API RESPONSE INFO */

//FODER_INFO
#define MOBIHELP_API_RESPONSE_FOLDER_ID                @"id"
#define MOBIHELP_API_RESPONSE_FOLDER_NAME              @"name"
#define MOBIHELP_API_RESPONSE_FOLDER_POSITION          @"position"
#define MOBIHELP_API_RESPONSE_FOLDER_CATEGORY_ID       @"category_id"
#define MOBIHELP_API_RESPONSE_FOLDER_DESCRIPTION       @"description"
#define MOBIHELP_API_RESPONSE_FOLDERS_PATH             @"folder.name"

//ARTICLES_INFO
#define MOBIHELP_API_RESPONSE_ARTICLE_ID               @"id"
#define MOBIHELP_API_RESPONSE_ARTICLE_TITLE            @"title"
#define MOBIHELP_API_RESPONSE_ARTICLE_POSITION         @"position"
#define MOBIHELP_API_RESPONSE_ARTICLE_DESCRIPTION      @"description"
#define MOBIHELP_API_RESPONSE_ARTICLE_DESC_PLAIN_TEXT  @"desc_un_html"

//TAGS INFO
#define MOBIHELP_API_RESPONSE_TAG_NAME @"name"
#define MOBIHELP_API_RESPONSE_TAGS @"tags"


//TICKETS_INFO
#define MOBIHELP_API_RESPONSE_TICKET_ID_PATH           @"ticket.helpdesk_ticket.display_id"
#define MOBIHELP_API_RESPONSE_TICKET_STATUS_PATH       @"ticket.helpdesk_ticket.status"
#define MOBIHELP_API_RESPONSE_TICKET_SUBJECT_PATH      @"ticket.helpdesk_ticket.subject"
#define MOBIHELP_API_RESPONSE_TICKET_DESCRIPTION_PATH  @"ticket.helpdesk_ticket.description"
#define MOBIHELP_API_RESPONSE_TICKET_CREATED_DATE_PATH @"ticket.helpdesk_ticket.created_at"
#define MOBIHELP_API_RESPONSE_TICKET_UPDATED_DATE_PATH @"ticket.helpdesk_ticket.updated_at"
#define MOBIHELP_API_RESPONSE_TICKET_REQUESTER_ID_PATH @"ticket.helpdesk_ticket.requester_id"

//NOTE_INFO
#define MOBIHELP_API_RESPONSE_NOTE_ID_PATH             @"helpdesk_ticket.notes.note.id"
#define MOBIHELP_API_RESPONSE_NOTE_BODY_PATH           @"helpdesk_ticket.notes.note.body"
#define MOBIHELP_API_RESPONSE_NOTE_CREATED_DATE_PATH   @"helpdesk_ticket.notes.note.created_at"
#define MOBIHELP_API_RESPONSE_NOTE_INCOMING_PATH       @"helpdesk_ticket.notes.note.incoming"
#define MOBIHELP_API_RESPONSE_NOTE_SOURCE              @"helpdesk_ticket.notes.note.source"

#endif
