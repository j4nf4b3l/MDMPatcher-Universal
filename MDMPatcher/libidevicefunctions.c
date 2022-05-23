

#include "libidevicefunctions.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <getopt.h>
#include <inttypes.h>
#include <libirecovery.h>
#include <readline/readline.h>
#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/property_list_service.h>
#include <readline/history.h>
#include <math.h>
#include <sys/stat.h>
#include "utils.h"
#include <plist/plist.h>
#include <util.h>
#include <libimobiledevice/mobileactivation.h>

static const char *domains[] = {
    "com.apple.disk_usage",
    "com.apple.disk_usage.factory", /// Disk usage
    "com.apple.mobile.battery", // Battery % rn
/* FIXME: For some reason lockdownd segfaults on this, works sometimes though . */
    "com.apple.mobile.debug",
    "com.apple.SystemConfiguration",
    "com.apple.iqagent",
    "com.apple.purplebuddy", /// useless info
    "com.apple.PurpleBuddy", /// internal settings detail
    "com.apple.mobile.chaperone",
    "com.apple.mobile.third_party_termination",
    "com.apple.mobile.lockdownd",
    "com.apple.mobile.lockdown_cache",
    "com.apple.xcode.developerdomain",
    "com.apple.international", /// language
    "com.apple.mobile.data_sync",
    "com.apple.mobile.tethered_sync",
    "com.apple.mobile.mobile_application_usage",
    "com.apple.mobile.backup",
    "com.apple.mobile.nikita",
    "com.apple.mobile.restriction",
    "com.apple.mobile.user_preferences",
    "com.apple.mobile.sync_data_class",
    "com.apple.mobile.software_behavior", // SwBh ChinaBlock...
    "com.apple.mobile.iTunes.SQLMusicLibraryPostProcessCommands",
    "com.apple.mobile.iTunes.accessories", /// nothing
    "com.apple.mobile.internal", /**< iOS 4.0+ */ /// factory check build/os
    "com.apple.mobile.wireless_lockdown", /**< iOS 4.0+ */ // remote sysnc url
    "com.apple.fairplay", /// Nothing
    "com.apple.iTunes",
    "com.apple.mobile.iTunes.store",
    "com.apple.mobile.iTunes",
    NULL
};

static int is_domain_known(const char *domain)
{
    int i = 0;
    while (domains[i] != NULL) {
        if (strstr(domain, domains[i++])) {
            return 1;
        }
    }
    return 0;
}

static irecv_client_t dev = NULL;
irecv_client_t client = NULL;
uint64_t ecid = 0;
irecv_error_t errors = 0;
char *output_xml = NULL;
int progress_cb(irecv_client_t client, const irecv_event_t* event);
void send_progress(double progress);
void send_progress_fz(unsigned int progress);
irecv_device_t device = NULL;


static swift_callbacks callback;
static swift_progress prog;

static const char* mode_to_str(int mode) {
    switch (mode) {
        case IRECV_K_RECOVERY_MODE_1:
        case IRECV_K_RECOVERY_MODE_2:
        case IRECV_K_RECOVERY_MODE_3:
        case IRECV_K_RECOVERY_MODE_4:
            return "Recovery";
            break;
        case IRECV_K_DFU_MODE:
            return "DFU";
            break;
        case IRECV_K_WTF_MODE:
            return "WTF";
            break;
        default:
            return "Unknown";
            break;
    }
}

extern void callback_setup(const swift_callbacks * callbacks) {
    callback = *callbacks;
}

extern void progress_setup(const swift_progress * callbacks) {
    prog = *callbacks;
}

int progress_cb(irecv_client_t client, const irecv_event_t* event) {
    if (event->type == IRECV_PROGRESS) {
        send_progress(event->progress);
    }
    
    return 0;
}




#define FORMAT_KEY_VALUE 1
#define FORMAT_XML 2
#define TOOL_NAME "ideviceinfo"


/// Customized Section

char *getdeviceInformation() // For getting general information about the device
{
    lockdownd_client_t client = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;
    idevice_t device = NULL;
    idevice_error_t ret = IDEVICE_E_UNKNOWN_ERROR;
    int simple = 0;
    int format = FORMAT_KEY_VALUE;
    const char* udid = NULL;
    int use_network = 0;
    const char *domain = NULL;
    const char *key = NULL;
    char *xml_doc = NULL;
    uint32_t xml_length;
    plist_t node = NULL;

    ret = idevice_new_with_options(&device, udid, (use_network) ? IDEVICE_LOOKUP_NETWORK : IDEVICE_LOOKUP_USBMUX);
    if (ret != IDEVICE_E_SUCCESS) {
        if (udid) {
            printf("ERROR: Device %s not found!\n", udid);
        } else {
            printf("ERROR: No device found!\n");
        }
        return "-1";
    }

    if (LOCKDOWN_E_SUCCESS != (ldret = simple ?
            lockdownd_client_new(device, &client, TOOL_NAME):
            lockdownd_client_new_with_handshake(device, &client, TOOL_NAME))) {
        fprintf(stderr, "ERROR: Could not connect to lockdownd: %s (%d)\n", lockdownd_strerror(ldret), ldret);
        idevice_free(device);
        return "-1";
    }

    if (domain && !is_domain_known(domain)) {
        fprintf(stderr, "WARNING: Sending query with unknown domain \"%s\".\n", domain);
    }
    
    

    /* run query and output information */
    if(lockdownd_get_value(client, domain, key, &node) == LOCKDOWN_E_SUCCESS) {
        if (node) {
            format = FORMAT_XML;
            switch (format) {
            case FORMAT_XML:
                plist_to_xml(node, &xml_doc, &xml_length);
                return xml_doc;
            case FORMAT_KEY_VALUE:
                //plist_print_to_stream(node, stdout);
                break;
            default:
                if (key != NULL)
                //plist_print_to_stream(node, stdout);
            break;
            }
            plist_free(node);
            node = NULL;
        }
    }

    lockdownd_client_free(client);
    idevice_free(device);

    return "0";
}

char *getspecialdeviceInformation(const char *domain_) // For getting general information about the device
{
    lockdownd_client_t client = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;
    idevice_t device = NULL;
    idevice_error_t ret = IDEVICE_E_UNKNOWN_ERROR;
    int simple = 0;
    int format = FORMAT_KEY_VALUE;
    const char* udid = NULL;
    int use_network = 0;
    const char *domain = domain_;
    const char *key = NULL;
    char *xml_doc = NULL;
    uint32_t xml_length;
    plist_t node = NULL;

    ret = idevice_new_with_options(&device, udid, (use_network) ? IDEVICE_LOOKUP_NETWORK : IDEVICE_LOOKUP_USBMUX);
    if (ret != IDEVICE_E_SUCCESS) {
        if (udid) {
            printf("ERROR: Device %s not found!\n", udid);
        } else {
            printf("ERROR: No device found!\n");
        }
        return "-1";
    }

    if (LOCKDOWN_E_SUCCESS != (ldret = simple ?
            lockdownd_client_new(device, &client, TOOL_NAME):
            lockdownd_client_new_with_handshake(device, &client, TOOL_NAME))) {
        fprintf(stderr, "ERROR: Could not connect to lockdownd: %s (%d)\n", lockdownd_strerror(ldret), ldret);
        idevice_free(device);
        return "-1";
    }

    if (domain && !is_domain_known(domain)) {
        fprintf(stderr, "WARNING: Sending query with unknown domain \"%s\".\n", domain);
    }
    
    

    /* run query and output information */
    if(lockdownd_get_value(client, domain, key, &node) == LOCKDOWN_E_SUCCESS) {
        if (node) {
            format = FORMAT_XML;
            switch (format) {
            case FORMAT_XML:
                plist_to_xml(node, &xml_doc, &xml_length);
                return xml_doc;
            case FORMAT_KEY_VALUE:
                //plist_print_to_stream(node, stdout);
                break;
            default:
                if (key != NULL)
                //plist_print_to_stream(node, stdout);
            break;
            }
            plist_free(node);
            node = NULL;
        }
    }

    lockdownd_client_free(client);
    idevice_free(device);

    return "0";
}

void send_progress(double progress) {
    if(progress < 0) {
        return;
    }
    if(progress > 100) {
        progress = 100;
    }
    prog.send_output_progress_to_swift(progress);
}


void send_progress_fz(unsigned int progress) {
    if(progress < 0) {
        return;
    }
    if(progress > 100) {
        progress = 100;
    }
    prog.send_output_progress_to_swift((double)progress);
}


void send_text(char *text) {
    int size = snprintf(NULL, 0, "%s", text);
    char * a = malloc(size + 1);
    sprintf(a, "%s", text);
    callback.send_output_to_swift(a);
}
