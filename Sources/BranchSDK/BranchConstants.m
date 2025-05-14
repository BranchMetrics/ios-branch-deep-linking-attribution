//
//  BranchConstants.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/10/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchConstants.h"

NSString * const BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN = @"randomized_bundle_token";
NSString * const BRANCH_REQUEST_KEY_DEVELOPER_IDENTITY = @"identity";
NSString * const BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN = @"randomized_device_token";
NSString * const BRANCH_REQUEST_KEY_SESSION_ID = @"session_id";
NSString * const BRANCH_REQUEST_KEY_ACTION = @"event";
NSString * const BRANCH_REQUEST_KEY_STATE = @"metadata";
NSString * const BRANCH_REQUEST_KEY_BUCKET = @"bucket";
NSString * const BRANCH_REQUEST_KEY_AMOUNT = @"amount";
NSString * const BRANCH_REQUEST_KEY_LENGTH = @"length";
NSString * const BRANCH_REQUEST_KEY_DIRECTION = @"direction";
NSString * const BRANCH_REQUEST_KEY_STARTING_TRANSACTION_ID = @"begin_after_id";
NSString * const BRANCH_REQUEST_KEY_URL_SOURCE = @"source";
NSString * const BRANCH_REQUEST_KEY_URL_TAGS = @"tags";
NSString * const BRANCH_REQUEST_KEY_URL_LINK_TYPE = @"type";
NSString * const BRANCH_REQUEST_KEY_URL_ALIAS = @"alias";
NSString * const BRANCH_REQUEST_KEY_URL_CHANNEL = @"channel";
NSString * const BRANCH_REQUEST_KEY_URL_FEATURE = @"feature";
NSString * const BRANCH_REQUEST_KEY_URL_STAGE = @"stage";
NSString * const BRANCH_REQUEST_KEY_URL_CAMPAIGN = @"campaign";
NSString * const BRANCH_REQUEST_KEY_URL_DURATION = @"duration";
NSString * const BRANCH_REQUEST_KEY_URL_DATA = @"data";
NSString * const BRANCH_REQUEST_KEY_URL_IGNORE_UA_STRING = @"ignore_ua_string";
NSString * const BRANCH_REQUEST_KEY_HARDWARE_ID = @"hardware_id";
NSString * const BRANCH_REQUEST_KEY_HARDWARE_ID_TYPE = @"hardware_id_type";
NSString * const BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL = @"is_hardware_id_real";
NSString * const BRANCH_REQUEST_KEY_IOS_VENDOR_ID = @"ios_vendor_id";
NSString * const BRANCH_REQUEST_KEY_OPTED_IN_STATUS = @"opted_in_status";
NSString * const BRANCH_REQUEST_KEY_FIRST_OPT_IN = @"first_opt_in";
NSString * const BRANCH_REQUEST_KEY_DEBUG = @"debug";
NSString * const BRANCH_REQUEST_KEY_BUNDLE_ID = @"ios_bundle_id";
NSString * const BRANCH_REQUEST_KEY_TEAM_ID = @"ios_team_id";
NSString * const BRANCH_REQUEST_KEY_APP_VERSION = @"app_version";
NSString * const BRANCH_REQUEST_KEY_OS = @"os";
NSString * const BRANCH_REQUEST_KEY_OS_VERSION = @"os_version";
NSString * const BRANCH_REQUEST_KEY_URI_SCHEME = @"uri_scheme";
NSString * const BRANCH_REQUEST_KEY_LINK_IDENTIFIER = @"link_identifier";
NSString * const BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER = @"spotlight_identifier";
NSString * const BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL = @"universal_link_url";
NSString * const BRANCH_REQUEST_KEY_LOCAL_URL = @"local_url";
NSString * const BRANCH_REQUEST_KEY_INITIAL_REFERRER = @"initial_referrer";
NSString * const BRANCH_REQUEST_KEY_BRAND = @"brand";
NSString * const BRANCH_REQUEST_KEY_MODEL = @"model";
NSString * const BRANCH_REQUEST_KEY_SCREEN_WIDTH = @"screen_width";
NSString * const BRANCH_REQUEST_KEY_SCREEN_HEIGHT = @"screen_height";
NSString * const BRANCH_REQUEST_KEY_IS_SIMULATOR = @"is_simulator";
NSString * const BRANCH_REQUEST_KEY_LOG = @"log";
NSString * const BRANCH_REQUEST_KEY_INSTRUMENTATION = @"instrumentation";
NSString * const BRANCH_REQUEST_KEY_APPLE_RECEIPT = @"apple_receipt";
NSString * const BRANCH_REQUEST_KEY_APPLE_TESTFLIGHT = @"apple_testflight";

NSString * const BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID = @"app_clip_bundle_id";
NSString * const BRANCH_REQUEST_KEY_LATEST_APP_CLIP_INSTALL_TIME = @"latest_app_clip_time";
NSString * const BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN = @"app_clip_randomized_device_token";
NSString * const BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_BUNDLE_TOKEN = @"app_clip_randomized_bundle_token";

NSString * const BRANCH_REQUEST_KEY_PARTNER_PARAMETERS = @"partner_data";

NSString * const BRANCH_REQUEST_METADATA_KEY_SCANTIME_WINDOW = @"skan_time_window";
NSString * const BRANCH_REQUEST_KEY_REFERRER_GBRAID = @"gbraid";
NSString * const BRANCH_REQUEST_KEY_REFERRER_GBRAID_TIMESTAMP = @"gbraid_timestamp";
NSString * const BRANCH_REQUEST_KEY_IS_DEEPLINK_GBRAID = @"is_deeplink_gbraid";
NSString * const BRANCH_REQUEST_KEY_GCLID = @"gclid";
NSString * const BRANCH_REQUEST_KEY_ODM_INFO = @"odm_info";
NSString * const BRANCH_REQUEST_KEY_ODM_FIRST_OPEN_TIMESTAMP = @"odm_first_open_timestamp";
NSString * const BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS = @"meta_campaign_ids";
NSString * const BRANCH_URL_QUERY_PARAMETERS_NAME_KEY = @"name";
NSString * const BRANCH_URL_QUERY_PARAMETERS_VALUE_KEY = @"value";
NSString * const BRANCH_URL_QUERY_PARAMETERS_TIMESTAMP_KEY = @"timestamp";
NSString * const BRANCH_URL_QUERY_PARAMETERS_IS_DEEPLINK_KEY = @"isDeepLink";
NSString * const BRANCH_URL_QUERY_PARAMETERS_VALIDITY_WINDOW_KEY = @"validityWindow";
NSString * const BRANCH_REQUEST_KEY_SCCID = @"sccid";
NSString * const BRANCH_REQUEST_KEY_WEB_LINK_CONTEXT = @"web_link_context";
NSString * const BRANCH_REQUEST_KEY_UX_TYPE = @"ux_type";
NSString * const BRANCH_REQUEST_KEY_URL_LOAD_MS = @"url_load_ms";

NSString * const BRANCH_REQUEST_ENDPOINT_APP_LINK_SETTINGS = @"app-link-settings";
NSString * const BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION = @"event";
NSString * const BRANCH_REQUEST_ENDPOINT_GET_SHORT_URL = @"url";
NSString * const BRANCH_REQUEST_ENDPOINT_OPEN = @"open";
NSString * const BRANCH_REQUEST_ENDPOINT_INSTALL = @"install";
NSString * const BRANCH_REQUEST_ENDPOINT_REGISTER_VIEW = @"register-view";
NSString * const BRANCH_REQUEST_ENDPOINT_LATD = @"cpid/latd";

NSString * const BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN = @"randomized_bundle_token";
NSString * const BRANCH_RESPONSE_KEY_SESSION_ID = @"session_id";
NSString * const BRANCH_RESPONSE_KEY_USER_URL = @"link";
NSString * const BRANCH_RESPONSE_KEY_INSTALL_PARAMS = @"referring_data";
NSString * const BRANCH_RESPONSE_KEY_REFERRER = @"referrer";
NSString * const BRANCH_RESPONSE_KEY_REFERREE = @"referree";
NSString * const BRANCH_RESPONSE_KEY_URL = @"url";
NSString * const BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER = @"spotlight_identifier";
NSString * const BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY = @"identity";
NSString * const BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN = @"randomized_device_token";
NSString * const BRANCH_RESPONSE_KEY_SESSION_DATA = @"data";
NSString * const BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK = @"+clicked_branch_link";
NSString * const BRANCH_RESPONSE_KEY_BRANCH_VIEW_DATA = @"branch_view_data";
NSString * const BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK = @"~referring_link";
NSString * const BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP = @"invoke_register_app";
NSString * const BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE = @"update_conversion_value";
NSString * const BRANCH_RESPONSE_KEY_COARSE_KEY = @"coarse_key";
NSString * const BRANCH_RESPONSE_KEY_UPDATE_IS_LOCKED = @"locked";
NSString * const BRANCH_RESPONSE_KEY_ASCENDING_ONLY = @"ascending_only";
NSString * const BRANCH_RESPONSE_KEY_INVOKE_FEATURES = @"invoke_features";
NSString * const BRANCH_RESPONSE_KEY_ENHANCED_WEB_LINK_UX = @"enhanced_web_link_ux";
NSString * const BRANCH_RESPONSE_KEY_WEB_LINK_REDIRECT_URL = @"web_link_redirect_url";

NSString * const BRANCH_LINK_DATA_KEY_OG_TITLE = @"$og_title";
NSString * const BRANCH_LINK_DATA_KEY_OG_DESCRIPTION = @"$og_description";
NSString * const BRANCH_LINK_DATA_KEY_OG_IMAGE_URL = @"$og_image_url";
NSString * const BRANCH_LINK_DATA_KEY_TITLE = @"+spotlight_title";
NSString * const BRANCH_LINK_DATA_KEY_DESCRIPTION = @"+spotlight_description";
NSString * const BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE = @"$publicly_indexable";
NSString * const BRANCH_LINK_DATA_KEY_LOCALLY_INDEXABLE = @"$locally_indexable";

NSString * const BRANCH_LINK_DATA_KEY_TYPE = @"+spotlight_type";
NSString * const BRANCH_LINK_DATA_KEY_THUMBNAIL_URL = @"+spotlight_thumbnail_url";
NSString * const BRANCH_LINK_DATA_KEY_KEYWORDS = @"$keywords";
NSString * const BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER = @"$canonical_identifier";
NSString * const BRANCH_LINK_DATA_KEY_CANONICAL_URL = @"$canonical_url";
NSString * const BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE = @"$exp_date";
NSString * const BRANCH_LINK_DATA_KEY_CONTENT_TYPE = @"$content_type";
NSString * const BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT = @"$email_subject";
NSString * const BRANCH_LINK_DATA_KEY_EMAIL_HTML_HEADER = @"$email_html_header";
NSString * const BRANCH_LINK_DATA_KEY_EMAIL_HTML_FOOTER = @"$email_html_footer";
NSString * const BRANCH_LINK_DATA_KEY_EMAIL_HTML_LINK_TEXT = @"$email_html_link_text";

NSString * const BRANCH_SPOTLIGHT_PREFIX = @"io.branch.link.v1";

NSString * const BRANCH_MANIFEST_VERSION_KEY = @"mv";
NSString * const BRANCH_HASH_MODE_KEY = @"h";
NSString * const BRANCH_MANIFEST_KEY = @"m";
NSString * const BRANCH_PATH_KEY = @"p";
NSString * const BRANCH_FILTERED_KEYS = @"ck";
NSString * const BRANCH_MAX_TEXT_LEN_KEY = @"mtl";
NSString * const BRANCH_MAX_VIEW_HISTORY_LENGTH = @"mhl";
NSString * const BRANCH_MAX_PACKET_SIZE_KEY = @"mps";
NSString * const BRANCH_CONTENT_DISCOVER_KEY = @"cd";
NSString * const BRANCH_BUNDLE_IDENTIFIER = @"pn";
NSString * const BRANCH_TIME_STAMP_KEY = @"ts";
NSString * const BRANCH_TIME_STAMP_CLOSE_KEY = @"tc";
NSString * const BRANCH_NAV_PATH_KEY = @"n";
NSString * const BRANCH_REFERRAL_LINK_KEY = @"rl";
NSString * const BRANCH_CONTENT_LINK_KEY = @"cl";
NSString * const BRANCH_CONTENT_META_DATA_KEY = @"cm";
NSString * const BRANCH_VIEW_KEY = @"v";
NSString * const BRANCH_CONTENT_DATA_KEY = @"cd";
NSString * const BRANCH_CONTENT_KEYS_KEY = @"ck";
NSString * const BRANCH_PACKAGE_NAME_KEY = @"p";
NSString * const BRANCH_ENTITIES_KEY = @"e";

NSString * const BRANCH_REQUEST_KEY_APPLE_ATTRIBUTION_TOKEN = @"apple_attribution_token";

NSString * const BRANCH_CRASHLYTICS_SDK_VERSION_KEY = @"io.branch.sdk.version";
NSString * const BRANCH_CRASHLYTICS_LOW_MEMORY_KEY = @"io.branch.device.lowmemory";

NSString * const BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI = @"external_intent_uri";

NSString * const BRANCH_REQUEST_KEY_SKAN_POSTBACK_INDEX = @"skan_postback_index";
NSString * const BRANCH_REQUEST_KEY_VALUE_POSTBACK_SEQUENCE_INDEX_0 = @"postback-sequence-index-0";
NSString * const BRANCH_REQUEST_KEY_VALUE_POSTBACK_SEQUENCE_INDEX_1 = @"postback-sequence-index-1";
NSString * const BRANCH_REQUEST_KEY_VALUE_POSTBACK_SEQUENCE_INDEX_2 = @"postback-sequence-index-2";

NSString * const BRANCH_REQUEST_KEY_DMA_EEA = @"dma_eea";
NSString * const BRANCH_REQUEST_KEY_DMA_AD_PEROSALIZATION = @"dma_ad_personalization";
NSString * const BRANCH_REQUEST_KEY_DMA_AD_USER_DATA = @"dma_ad_user_data";

NSString * const BRANCH_REQUEST_KEY_CPP_LEVEL = @"cpp_level";

NSString * const BRANCH_REQUEST_KEY_REQUEST_UUID = @"branch_sdk_request_unique_id";
NSString * const BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP = @"branch_sdk_request_timestamp";

NSString * const WEB_UX_IN_APP_WEBVIEW = @"IN_APP_WEBVIEW";
NSString * const WEB_UX_EXTERNAL_BROWSER = @"EXTERNAL_BROWSER";
