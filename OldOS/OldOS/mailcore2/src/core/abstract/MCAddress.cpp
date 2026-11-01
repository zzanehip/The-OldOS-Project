#include "MCWin32.h" // should be included first.

#include "MCAddress.h"

#include <libetpan/libetpan.h>
#include <string.h>

#include "MCDefines.h"

using namespace mailcore;

static Array * lep_address_list_from_lep_mailbox(struct mailimf_mailbox_list * mb_list, int encoded);
static Array * lep_address_list_from_lep_addr(struct mailimf_address_list * addr_list, int encoded);

Address::Address()
{
    init();
}

Address::Address(Address * other)
{
    init();
    setDisplayName(other->displayName());
    setMailbox(other->mailbox());
}

void Address::init()
{
    mDisplayName = NULL;
    mMailbox = NULL;
}

Address::~Address()
{
    MC_SAFE_RELEASE(mDisplayName);
    MC_SAFE_RELEASE(mMailbox);
}

Address * Address::addressWithDisplayName(String * displayName, String * mailbox)
{
    Address * result = new Address();
    result->setDisplayName(displayName);
    result->setMailbox(mailbox);
    return (Address *) result->autorelease();
}

Address * Address::addressWithMailbox(String * mailbox)
{
    return addressWithDisplayName(NULL, mailbox);
}

Address * Address::addressWithIMFMailbox(struct mailimf_mailbox * mailbox)
{
    Address * address;
    
    address = new Address();
    if (mailbox->mb_display_name != NULL) {
        address->setDisplayName(String::stringByDecodingMIMEHeaderValue(mailbox->mb_display_name));
    }
    if (mailbox->mb_addr_spec != NULL) {
        address->setMailbox(String::stringWithUTF8Characters(mailbox->mb_addr_spec));
    }
    if (address->mailbox() == NULL) {
        address->setMailbox(String::string());
    }
    
    return (Address *) address->autorelease();
}

Address * Address::addressWithIMAPAddress(struct mailimap_address * imap_addr)
{
    char * dsp_name;
    Address * address;
    String * mailbox;

    if (imap_addr->ad_personal_name == NULL)
        dsp_name = NULL;
    else {
        dsp_name = imap_addr->ad_personal_name;
    }

    if (imap_addr->ad_host_name == NULL) {
        const char * addr;

        if (imap_addr->ad_mailbox_name == NULL) {
            addr = "";
        }
        else {
            addr = imap_addr->ad_mailbox_name;
        }
        mailbox = String::stringByDecodingMIMEHeaderValue(addr);
        if (mailbox == NULL) {
            mailbox = MCSTR("");
        }
    }
    else if (imap_addr->ad_mailbox_name == NULL) {
        // fix by Gabor Cselle, (http://gaborcselle.com/), reported 8/16/2009
        mailbox = String::stringWithUTF8Format("@%s", imap_addr->ad_host_name);
    }
    else {
        mailbox = String::stringWithUTF8Format("%s@%s", imap_addr->ad_mailbox_name, imap_addr->ad_host_name);
    }

    address = new Address();
    if (dsp_name != NULL) {
        address->setDisplayName(String::stringByDecodingMIMEHeaderValue(dsp_name));
    }
    address->setMailbox(mailbox);

    return (Address *) address->autorelease();
}

Address * Address::addressWithRFC822String(String * RFC822String)
{
    const char * utf8String;
    size_t currentIndex;
    struct mailimf_mailbox * mb;
    int r;
    Address * result;
    
    utf8String = RFC822String->UTF8Characters();
    currentIndex = 0;
    r = mailimf_mailbox_parse(utf8String, strlen(utf8String), &currentIndex, &mb);
    if (r != MAILIMF_NO_ERROR)
        return NULL;
    
    result = addressWithIMFMailbox(mb);
    mailimf_mailbox_free(mb);
    
    return result;
}

Address * Address::addressWithNonEncodedIMFMailbox(struct mailimf_mailbox * mailbox)
{
    Address * address;
    
    address = new Address();
    if (mailbox->mb_display_name != NULL) {
        address->setDisplayName(String::stringWithUTF8Characters(mailbox->mb_display_name));
    }
    if (mailbox->mb_addr_spec != NULL) {
        address->setMailbox(String::stringWithUTF8Characters(mailbox->mb_addr_spec));
    }
    if (address->mailbox() == NULL) {
        address->setMailbox(String::string());
    }
    
    return (Address *) address->autorelease();
}

Address * Address::addressWithNonEncodedRFC822String(String * nonEncodedRFC822String)
{
    const char * utf8String;
    size_t currentIndex;
    struct mailimf_mailbox * mb;
    int r;
    Address * result;
    
    utf8String = nonEncodedRFC822String->UTF8Characters();
    currentIndex = 0;
    r = mailimf_mailbox_parse(utf8String, strlen(utf8String), &currentIndex, &mb);
    if (r != MAILIMF_NO_ERROR)
        return NULL;
    
    result = addressWithNonEncodedIMFMailbox(mb);
    mailimf_mailbox_free(mb);
    
    return result;
}

Array * Address::addressesWithRFC822String(String * string)
{
    const char * utf8String;
    size_t currentIndex;
    struct mailimf_address_list * addr_list;
    Array * result;
    int r;

    if (string == NULL) {
        return NULL;
    }

    utf8String = string->UTF8Characters();
    currentIndex = 0;
    
    r = mailimf_address_list_parse(utf8String, strlen(utf8String), &currentIndex, &addr_list);
    if (r != MAILIMF_NO_ERROR)
        return NULL;
    
    result = lep_address_list_from_lep_addr(addr_list, 1);
    mailimf_address_list_free(addr_list);
    
    return result;
}

Array * Address::addressesWithNonEncodedRFC822String(String * string)
{
    const char * utf8String;
    size_t currentIndex;
    struct mailimf_address_list * addr_list;
    Array * result;
    int r;
    
    utf8String = string->UTF8Characters();
    currentIndex = 0;
    
    r = mailimf_address_list_parse(utf8String, strlen(utf8String), &currentIndex, &addr_list);
    if (r != MAILIMF_NO_ERROR)
        return NULL;
    
    result = lep_address_list_from_lep_addr(addr_list, 0);
    mailimf_address_list_free(addr_list);
    
    return result;
}

String * Address::RFC822StringForAddresses(Array * addresses)
{
    String * result = String::string();
    if (addresses == NULL) {
        return result;
    }
    for(unsigned int i = 0 ; i < addresses->count() ; i ++) {
        Address * address = (Address *) addresses->objectAtIndex(i);
        if (i != 0) {
            result->appendString(MCSTR(", "));
        }
        result->appendString(address->RFC822String());
    }
    return result;
}

String * Address::nonEncodedRFC822StringForAddresses(Array * addresses)
{
    String * result = String::string();
    if (addresses == NULL) {
        return result;
    }
    for(unsigned int i = 0 ; i < addresses->count() ; i ++) {
        Address * address = (Address *) addresses->objectAtIndex(i);
        if (i != 0) {
            result->appendString(MCSTR(", "));
        }
        result->appendString(address->nonEncodedRFC822String());
    }
    return result;
}

String * Address::description()
{
    String * result = String::string();
    result->appendString(className());
    result->appendUTF8Format(":%p ", this);
    if (mDisplayName != NULL) {
        result->appendString(mDisplayName);
    }
    result->appendUTF8Characters(" <");
    if (mMailbox != NULL) {
        result->appendString(mMailbox);
    }
    result->appendUTF8Characters(">");
    
    return result;
}

bool Address::isEqual(Object * otherObject)
{
    Address * otherAddress = (Address *) otherObject;
    
    if (mDisplayName == NULL) {
        if (otherAddress->displayName() != NULL) {
            return false;
        }
    }
    else if (mDisplayName != NULL) {
        if (otherAddress->displayName() == NULL) {
            return false;
        }
        else {
            if (!mDisplayName->isEqual(otherAddress->displayName()))
                return false;
        }
    }
    
    if (mMailbox == NULL) {
        if (otherAddress->mailbox() != NULL) {
            return false;
        }
    }
    else if (mMailbox != NULL) {
        if (otherAddress->mailbox() == NULL) {
            return false;
        }
        else {
            if (!mMailbox->isEqual(otherAddress->mailbox()))
                return false;
        }
    }
    
    return true;
}

unsigned int Address::hash()
{
    unsigned int value;
    
    value = 0;
    if (mDisplayName != NULL) {
        value += mDisplayName->hash();
    }
    if (mMailbox != NULL) {
        value += mMailbox->hash();
    }
    
    return value;
}

Object * Address::copy()
{
    return new Address(this);
}

void Address::setDisplayName(String * displayName)
{
    MC_SAFE_REPLACE_COPY(String, mDisplayName, displayName);
}

String * Address::displayName()
{
    return mDisplayName;
}

void Address::setMailbox(String * mailbox)
{
    MC_SAFE_REPLACE_COPY(String, mMailbox, mailbox);
}

String * Address::mailbox()
{
    return mMailbox;
}

struct mailimf_address * Address::createIMFAddress()
{
    struct mailimf_mailbox * mailbox;
    struct mailimf_address * result;
    
    mailbox = createIMFMailbox();
    result = mailimf_address_new(MAILIMF_ADDRESS_MAILBOX, mailbox, NULL);
    
    return result;
}

struct mailimf_mailbox * Address::createIMFMailbox()
{
    struct mailimf_mailbox * result;
    char * display_name;
    char * addr_spec;
    
    display_name = NULL;
    if (displayName() != NULL) {
        if (displayName()->length() > 0) {
            Data * data;
            
            data = displayName()->encodedAddressDisplayNameValue();
            if (data->bytes() != NULL) {
                display_name = strdup(data->bytes());
            }
        }
    }
    addr_spec = strdup(mailbox()->UTF8Characters());
    result = mailimf_mailbox_new(display_name, addr_spec);
    
    return result;
}

String * Address::RFC822String()
{
    struct mailimf_mailbox * mb;
    MMAPString * str;
    int col;
    struct mailimf_mailbox_list * mb_list;
    clist * list;
    String * result;
    
    mb = createIMFMailbox();
    
    list = clist_new();
    clist_append(list, mb);
    mb_list = mailimf_mailbox_list_new(list);
    
    str = mmap_string_new("");
    col = 0;
    mailimf_mailbox_list_write_mem(str, &col, mb_list);
    
    result = String::stringWithUTF8Characters(str->str);
    
    mailimf_mailbox_list_free(mb_list);
    mmap_string_free(str);
    
    return result;
}

String * Address::nonEncodedRFC822String()
{
    struct mailimf_mailbox * mb;
    MMAPString * str;
    int col;
    struct mailimf_mailbox_list * mb_list;
    clist * list;
    String * result;
    char * display_name;
    char * addr_spec;
    
    display_name = NULL;
    if (displayName() != NULL) {
        if (displayName()->length() > 0) {
            display_name = strdup(displayName()->UTF8Characters());
        }
    }
    if ((mailbox() == NULL) || (mailbox()->length() == 0)) {
        addr_spec = strdup("invalid");
    }
    else {
        addr_spec = strdup(mailbox()->UTF8Characters());
    }
    mb = mailimf_mailbox_new(display_name, addr_spec);
    
    list = clist_new();
    clist_append(list, mb);
    mb_list = mailimf_mailbox_list_new(list);
    
    str = mmap_string_new("");
    col = 0;
    mailimf_mailbox_list_write_mem(str, &col, mb_list);
    
    result = String::stringWithUTF8Characters(str->str);
    
    mailimf_mailbox_list_free(mb_list);
    mmap_string_free(str);
    
    return result;
}

static Array * lep_address_list_from_lep_mailbox(struct mailimf_mailbox_list * mb_list, int encoded)
{
    Array * result;
    clistiter * cur;
    
    result = Array::array();
    for(cur = clist_begin(mb_list->mb_list) ; cur != NULL ; cur = clist_next(cur)) {
        struct mailimf_mailbox * mb;
        Address * address;
        
        mb = (mailimf_mailbox *) clist_content(cur);
        if (encoded) {
            address = Address::addressWithIMFMailbox(mb);
        }
        else {
            address = Address::addressWithNonEncodedIMFMailbox(mb);
        }
        result->addObject(address);
    }
    
    return result;
}

static Array * lep_address_list_from_lep_addr(struct mailimf_address_list * addr_list, int encoded)
{
    Array * result;
    clistiter * cur;
    
    result = Array::array();
    
    for(cur = clist_begin(addr_list->ad_list) ; cur != NULL ;
        cur = clist_next(cur)) {
        struct mailimf_address * addr;
        
        addr =  (mailimf_address *) clist_content(cur);
        switch (addr->ad_type) {
            case MAILIMF_ADDRESS_MAILBOX:
            {
                Address * address;
                
                if (encoded) {
                    address = Address::addressWithIMFMailbox(addr->ad_data.ad_mailbox);
                }
                else {
                    address = Address::addressWithNonEncodedIMFMailbox(addr->ad_data.ad_mailbox);
                }
                result->addObject(address);
                break;
            }
                
            case MAILIMF_ADDRESS_GROUP:
            {
                if (addr->ad_data.ad_group->grp_mb_list != NULL) {
                    Array * subArray;
                    
                    subArray = lep_address_list_from_lep_mailbox(addr->ad_data.ad_group->grp_mb_list, encoded);
                    result->addObjectsFromArray(subArray);
                }
                break;
            }
        }
    }
    
    return result;
}

static void * createObject()
{
    return new Address();
}

HashMap * Address::serializable()
{
    HashMap * result = Object::serializable();
    if (mailbox() != NULL) {
        result->setObjectForKey(MCSTR("mailbox"), mailbox());
    }
    if (displayName() != NULL) {
        result->setObjectForKey(MCSTR("displayName"), displayName());
    }
    return result;
}

void Address::importSerializable(HashMap * serializable)
{
    setMailbox((String *) serializable->objectForKey(MCSTR("mailbox")));
    setDisplayName((String *) serializable->objectForKey(MCSTR("displayName")));
}

INITIALIZE(Address)
{
    Object::registerObjectConstructor("mailcore::Address", &createObject);
}

