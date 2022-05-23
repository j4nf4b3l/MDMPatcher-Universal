

#ifndef libidevicefunctions_h
#define libidevicefunctions_h

#include <stdio.h>
#include <plist/plist.h>
int sendiBEC(char *iBECpath);
int get_dev();

char* diag(char* com, char* mobileGestaltKey);
char *getdeviceInformation();
char *getspecialdeviceInformation(const char *domain_);
int activationHandler(int function, char *udidIN);
void plist_print_to_stream(plist_t plist, FILE* stream);
void ActivationProgress(int x);
char *output_xml;
const char* title ;
const char* describtion ;
char* AppleID;
char* ID_Password;

char * send_state();
static int read_file_into_buffer(char* path, char** buf, size_t* len);
static int load_ibec(char* path, char** ibec, size_t* ibec_len);
int boot_client(void* buf, size_t sz);
int sendiBSS(char *iBSSpath);
int sendDeviceTree(char *DeviceTree_Path);
int sendKernelCache(char *KernelCache_Path);
int dfu_send_iBSS(char *iBSSpath);
int dfu_send_iBEC(char *iBECpath);
int ipsw_outside_file_extract_to_memory_boot(const char *infile, unsigned char **pbuffer, size_t *psize, char* outside_path);
int extract_outside_component_boot(const char* path, unsigned char** component_data, size_t* component_size, char* outside_path);
static int read_file_into_buffer(char* path, char** buf, size_t* len);
int boot_ibec(const char* outside_path);
int boot_ibss(const char* outside_path);
int download_component(const char* url, const char* component, const char* outdir);
///

struct swift_callbacks {
    void (* _Nonnull send_output_to_swift)(const char * _Nonnull modifier);
};
typedef struct swift_callbacks swift_callbacks;

extern void callback_setup(const swift_callbacks * _Nonnull callbacks);

///

typedef void (*callback_t)(void);

void callBackIntoSwift( callback_t cb );

struct swift_progresss {
    void (* _Nonnull send_output_progress_to_swift)(double modifier);
};
typedef struct swift_progresss swift_progress;

extern void progress_setup(const swift_progress* _Nonnull callbacks);
int test_prog();
char * send_ecid();

#endif /* libidevicefunctions_h */
