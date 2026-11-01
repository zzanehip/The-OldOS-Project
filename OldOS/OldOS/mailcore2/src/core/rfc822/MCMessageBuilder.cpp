#include "MCWin32.h" // Should be included first.

#include "MCMessageBuilder.h"

#include "MCMessageHeader.h"
#include "MCAttachment.h"
#include "MCMessageParser.h"

#include <stdlib.h>
#ifndef _MSC_VER
#include <unistd.h>
#endif
#include <string.h>
#include <libetpan/libetpan.h>

using namespace mailcore;

static char * generate_boundary(const char * boundary_prefix);
struct mailmime * part_multiple_new(MessageBuilder * builder, const char * type, const char * boundary_prefix);
static struct mailmime *
part_new_empty(MessageBuilder * builder, struct mailmime_content * content,
               struct mailmime_fields * mime_fields,
               const char * boundary_prefix,
               int force_single);

static struct mailmime * get_multipart_alternative(MessageBuilder * builder, const char * boundary_prefix)
{
    struct mailmime * mime;
    
    mime = part_multiple_new(builder, "multipart/alternative", boundary_prefix);
    
    return mime;
}

static struct mailmime * get_multipart_related(MessageBuilder * builder, const char * boundary_prefix)
{
    struct mailmime * mime;
    
    mime = part_multiple_new(builder, "multipart/related", boundary_prefix);
    
    return mime;
}

static struct mailmime * get_multipart_signed_pgp(MessageBuilder * builder, const char * boundary_prefix)
{
    struct mailmime * mime;
    
    mime = part_multiple_new(builder, "multipart/signed", boundary_prefix);
    struct mailmime_parameter * param = mailmime_param_new_with_data((char *) "protocol", (char *) "application/pgp-signature");
    clist_append(mime->mm_content_type->ct_parameters, param);
    
    return mime;
}

static struct mailmime * get_multipart_encrypted_pgp(MessageBuilder * builder, const char * boundary_prefix)
{
    struct mailmime * mime;
    
    mime = part_multiple_new(builder, "multipart/encrypted", boundary_prefix);
    struct mailmime_parameter * param = mailmime_param_new_with_data((char *) "protocol", (char *) "application/pgp-encrypted");
    clist_append(mime->mm_content_type->ct_parameters, param);
    
    return mime;
}

static int add_attachment(MessageBuilder * builder, struct mailmime * mime,
    struct mailmime * mime_sub,
    const char * boundary_prefix)
{
    struct mailmime * saved_sub;
    struct mailmime * mp;
    int res;
    int r;
    
    switch (mime->mm_type) {
        case MAILMIME_SINGLE:
            res = MAILIMF_ERROR_INVAL;
            goto err;
            
        case MAILMIME_MULTIPLE:
            r = mailmime_add_part(mime, mime_sub);
            if (r != MAILIMF_NO_ERROR) {
                res = MAILIMF_ERROR_MEMORY;
                goto err;
            }
            
            return MAILIMF_NO_ERROR;
    }
    
    /* MAILMIME_MESSAGE */
    
    if (mime->mm_data.mm_message.mm_msg_mime == NULL) {
        /* there is no subpart, we can simply attach it */
        
        r = mailmime_add_part(mime, mime_sub);
        if (r != MAILIMF_NO_ERROR) {
            res = MAILIMF_ERROR_MEMORY;
            goto err;
        }
        
        return MAILIMF_NO_ERROR;
    }
    
    if (mime->mm_data.mm_message.mm_msg_mime->mm_type == MAILMIME_MULTIPLE &&
        strcasecmp(mime->mm_data.mm_message.mm_msg_mime->mm_content_type->ct_subtype, "alternative") != 0) {
        /* in case the subpart is multipart, simply attach it to the subpart */
        
        return mailmime_add_part(mime->mm_data.mm_message.mm_msg_mime, mime_sub);
    }
    
    /* we save the current subpart, ... */
    
    saved_sub = mime->mm_data.mm_message.mm_msg_mime;
    
    /* create a multipart */
    
    mp = part_multiple_new(builder, "multipart/mixed", boundary_prefix);
    if (mp == NULL) {
        res = MAILIMF_ERROR_MEMORY;
        goto err;
    }
    
    /* detach the saved subpart from the parent */
    
    mailmime_remove_part(saved_sub);
    
    /* the created multipart is the new child of the parent */
    
    r = mailmime_add_part(mime, mp);
    if (r != MAILIMF_NO_ERROR) {
        res = MAILIMF_ERROR_MEMORY;
        goto free_mp;
    }
    
    /* then, attach the saved subpart and ... */
    
    r = mailmime_add_part(mp, saved_sub);
    if (r != MAILIMF_NO_ERROR) {
        res = MAILIMF_ERROR_MEMORY;
        goto free_saved_sub;
    }
    
    /* the given part to the parent */
    
    r = mailmime_add_part(mp, mime_sub);
    if (r != MAILIMF_NO_ERROR) {
        res = MAILIMF_ERROR_MEMORY;
        goto free_saved_sub;
    }
    
    return MAILIMF_NO_ERROR;
    
free_mp:
    mailmime_free(mp);
free_saved_sub:
    mailmime_free(saved_sub);
err:
    return res;
}

static struct mailmime * get_text_part(MessageBuilder * builder,
                                       const char * mime_type, const char * charset, const char * content_id,
                                const char * description,
                                const char * text, size_t length, int encoding_type, clist * contentTypeParameters)
{
    struct mailmime_fields * mime_fields;
    struct mailmime * mime;
    struct mailmime_content * content;
    struct mailmime_parameter * param;
    struct mailmime_disposition * disposition;
    struct mailmime_mechanism * encoding;
    char * dup_content_id;
    char * dup_description;
    
    encoding = mailmime_mechanism_new(encoding_type, NULL);
    disposition = mailmime_disposition_new_with_data(MAILMIME_DISPOSITION_TYPE_INLINE,
                                                     NULL, NULL, NULL, NULL, (size_t) -1);
    dup_content_id = NULL;
    if (content_id != NULL)
        dup_content_id = strdup(content_id);
    dup_description = NULL;
    if (dup_description != NULL)
        dup_description = strdup(description);
    mime_fields = mailmime_fields_new_with_data(encoding,
                                                dup_content_id, dup_description, disposition, NULL);
    
    content = mailmime_content_new_with_str(mime_type);
    if (charset == NULL) {
        param = mailmime_param_new_with_data((char *) "charset", (char *) "utf-8");
    }
    else {
        param = mailmime_param_new_with_data((char *) "charset", (char *) charset);
    }
    clist_append(content->ct_parameters, param);
    if (contentTypeParameters != NULL) {
        clist_concat(content->ct_parameters, contentTypeParameters);
    }
    
    mime = part_new_empty(builder, content, mime_fields, NULL, 1);
    mailmime_set_body_text(mime, (char *) text, length);
    
    return mime;
}

static struct mailmime * get_plain_text_part(MessageBuilder * builder,
                                             const char * mime_type, const char * charset, const char * content_id,
                                      const char * description,
                                      const char * text, size_t length, clist * contentTypeParameters, bool forEncryption)
{
    bool needsQuotedPrintable;
    int mechanism;
    
    needsQuotedPrintable = false;
    if (forEncryption) {
        needsQuotedPrintable = true;
    }
    if (!needsQuotedPrintable) {
        for(size_t i = 0 ; i < length ; i ++) {
            if ((text[i] & (1 << 7)) != 0) {
                needsQuotedPrintable = true;
                break;
            }
        }
    }
    
    mechanism = MAILMIME_MECHANISM_7BIT;
    if (needsQuotedPrintable) {
        mechanism = MAILMIME_MECHANISM_QUOTED_PRINTABLE;
    }
    return get_text_part(builder, mime_type, charset, content_id, description, text, length, mechanism, contentTypeParameters);
}

static struct mailmime * get_other_text_part(MessageBuilder * builder,
                                             const char * mime_type, const char * charset, const char * content_id,
                                      const char * description,
                                      const char * text, size_t length, clist * contentTypeParameters)
{
    return get_text_part(builder, mime_type, charset, content_id, description, text, length, MAILMIME_MECHANISM_QUOTED_PRINTABLE, contentTypeParameters);
}

static struct mailmime * get_file_part(MessageBuilder * builder,
                                       const char * filename, const char * mime_type, int is_inline,
                                       const char * content_id,
                                       const char * content_description,
                                       const char * text, size_t length, clist * contentTypeParameters)
{
    char * disposition_name;
    int encoding_type;
    struct mailmime_disposition * disposition;
    struct mailmime_mechanism * encoding;
    struct mailmime_content * content;
    struct mailmime * mime;
    struct mailmime_fields * mime_fields;
    char * dup_content_id;
    char * dup_content_description;

    disposition_name = NULL;
    if (filename != NULL) {
        disposition_name = strdup(filename);
    }
    if (is_inline) {
        disposition = mailmime_disposition_new_with_data(MAILMIME_DISPOSITION_TYPE_INLINE,
                                                         disposition_name, NULL, NULL, NULL, (size_t) -1);
    }
    else {
        disposition = mailmime_disposition_new_with_data(MAILMIME_DISPOSITION_TYPE_ATTACHMENT,
                                                         disposition_name, NULL, NULL, NULL, (size_t) -1);
    }
    content = mailmime_content_new_with_str(mime_type);
    
    encoding_type = MAILMIME_MECHANISM_BASE64;
    encoding = mailmime_mechanism_new(encoding_type, NULL);
    dup_content_id = NULL;
    if (content_id != NULL)
        dup_content_id = strdup(content_id);
    dup_content_description = NULL;
    if (content_description != NULL)
        dup_content_description = strdup(content_description);
    mime_fields = mailmime_fields_new_with_data(encoding,
                                                dup_content_id, dup_content_description, disposition, NULL);
    
    if (contentTypeParameters != NULL) {
        clist_concat(content->ct_parameters, contentTypeParameters);
    }
    
    mime = part_new_empty(builder, content, mime_fields, NULL, 1);
    mailmime_set_body_text(mime, (char *) text, length);
    
    return mime;
}

#define MIME_ENCODED_STR(str) (str != NULL ? str->encodedMIMEHeaderValue()->bytes() : NULL)

static clist * content_type_parameters_from_attachment(Attachment * att)
{
    clist * contentTypeParameters = NULL;
    struct mailmime_parameter * param;
    
    mc_foreacharray(String, name, att->allContentTypeParametersNames()) {
        if (contentTypeParameters == NULL) {
            contentTypeParameters = clist_new();
        }
        String * value = att->contentTypeParameterValueForName(name);
        param = mailmime_param_new_with_data((char *)name->UTF8Characters(), (char *)value->UTF8Characters());
        clist_append(contentTypeParameters, param);
    }

    return contentTypeParameters;
}

static struct mailmime * mime_from_attachment(MessageBuilder * builder, Attachment * att, bool forEncryption)
{
    struct mailmime * mime;
    Data * data;
    int r;

    data = att->data();
    if (data == NULL) {
        data = Data::data();
    }
    if (att->mimeType()->lowercaseString()->isEqual(MCSTR("message/rfc822"))) {
        size_t indx = 0;
        r = mailmime_parse(data->bytes(), data->length(), &indx, &mime);
        if (r != MAILIMF_NO_ERROR)
            return NULL;
    }
    else {
        clist * contentTypeParameters = content_type_parameters_from_attachment(att);
        if (att->isInlineAttachment() && att->mimeType()->lowercaseString()->isEqual(MCSTR("text/plain"))) {
            mime = get_plain_text_part(builder, MCUTF8(att->mimeType()), MCUTF8(att->charset()),
                                       MCUTF8(att->contentID()),
                                       MIME_ENCODED_STR(att->contentDescription()),
                                       data->bytes(), data->length(),
                                       contentTypeParameters,
                                       forEncryption);
        }
        else if (att->isInlineAttachment() && att->mimeType()->lowercaseString()->hasPrefix(MCSTR("text/"))) {
            mime = get_other_text_part(builder, MCUTF8(att->mimeType()), MCUTF8(att->charset()),
                                       MCUTF8(att->contentID()),
                                       MIME_ENCODED_STR(att->contentDescription()),
                                       data->bytes(), data->length(),
                                       contentTypeParameters);
        }
        else {
            mime = get_file_part(builder, MIME_ENCODED_STR(att->filename()),
                                 MCUTF8(att->mimeType()), att->isInlineAttachment(),
                                 MCUTF8(att->contentID()),
                                 MIME_ENCODED_STR(att->contentDescription()),
                                 data->bytes(), data->length(),
                                 contentTypeParameters);
        }
        if (contentTypeParameters != NULL) {
            clist_free(contentTypeParameters);
        }
    }
    return mime;
}

static struct mailmime * multipart_related_from_attachments(MessageBuilder * builder,
    Attachment * htmlAttachment,
    Array * attachments, const char * boundary_prefix, bool forEncryption)
{
    if ((attachments != NULL) && (attachments->count() > 0)) {
        struct mailmime * submime;
        struct mailmime * mime;
        
        mime = get_multipart_related(builder, boundary_prefix);
        
        submime = mime_from_attachment(builder, htmlAttachment, forEncryption);
        add_attachment(builder, mime, submime, boundary_prefix);
        
        for(unsigned int i = 0 ; i < attachments->count() ; i ++) {
            Attachment * attachment;
            
            attachment = (Attachment *) attachments->objectAtIndex(i);
            submime = mime_from_attachment(builder, attachment, forEncryption);
            add_attachment(builder, mime, submime, boundary_prefix);
        }
        
        return mime;
    }
    else {
        struct mailmime * mime;
        
        mime = mime_from_attachment(builder, htmlAttachment, forEncryption);
        
        return mime;
    }
}

static struct mailmime *
part_new_empty(MessageBuilder * builder, struct mailmime_content * content,
               struct mailmime_fields * mime_fields,
               const char * boundary_prefix,
               int force_single)
{
    struct mailmime * build_info;
    clist * list;
    int r;
    int mime_type;
    
    list = NULL;
    
    if (force_single) {
        mime_type = MAILMIME_SINGLE;
    }
    else {
        switch (content->ct_type->tp_type) {
            case MAILMIME_TYPE_DISCRETE_TYPE:
                mime_type = MAILMIME_SINGLE;
                break;
                
            case MAILMIME_TYPE_COMPOSITE_TYPE:
                switch (content->ct_type->tp_data.tp_composite_type->ct_type) {
                    case MAILMIME_COMPOSITE_TYPE_MULTIPART:
                        mime_type = MAILMIME_MULTIPLE;
                        break;
                        
                    case MAILMIME_COMPOSITE_TYPE_MESSAGE:
                        if (strcasecmp(content->ct_subtype, "rfc822") == 0)
                            mime_type = MAILMIME_MESSAGE;
                        else
                            mime_type = MAILMIME_SINGLE;
                        break;
                        
                    default:
                        goto err;
                }
                break;
                
            default:
                goto err;
        }
    }
    
    if (mime_type == MAILMIME_MULTIPLE) {
        char * attr_name;
        char * attr_value;
        struct mailmime_parameter * param;
        clist * parameters;
        char * boundary;
        
        list = clist_new();
        if (list == NULL)
            goto err;
        
        attr_name = strdup("boundary");
        if (attr_name == NULL)
            goto free_list;
        
        if (builder != NULL) {
            String * boundaryString = builder->nextBoundary();
            boundary = strdup(boundaryString->UTF8Characters());
        }
        else {
            boundary = generate_boundary(boundary_prefix);
        }
        attr_value = boundary;
        if (attr_name == NULL) {
            free(attr_name);
            goto free_list;
        }
        
        param = mailmime_parameter_new(attr_name, attr_value);
        if (param == NULL) {
            free(attr_value);
            free(attr_name);
            goto free_list;
        }
        
        if (content->ct_parameters == NULL) {
            parameters = clist_new();
            if (parameters == NULL) {
                mailmime_parameter_free(param);
                goto free_list;
            }
        }
        else
            parameters = content->ct_parameters;
        
        r = clist_append(parameters, param);
        if (r != 0) {
            clist_free(parameters);
            mailmime_parameter_free(param);
            goto free_list;
        }
        
        if (content->ct_parameters == NULL)
            content->ct_parameters = parameters;
    }
    
    build_info = mailmime_new(mime_type,
                              NULL, 0, mime_fields, content,
                              NULL, NULL, NULL, list,
                              NULL, NULL);
    if (build_info == NULL) {
        clist_free(list);
        return NULL;
    }
    
    return build_info;
    
free_list:
    clist_free(list);
err:
    return NULL;
}

struct mailmime * part_multiple_new(MessageBuilder * builder, const char * type, const char * boundary_prefix)
{
    struct mailmime_fields * mime_fields;
    struct mailmime_content * content;
    struct mailmime * mp;
    
    mime_fields = mailmime_fields_new_empty();
    if (mime_fields == NULL)
        goto err;
    
    content = mailmime_content_new_with_str(type);
    if (content == NULL)
        goto free_fields;
    
    mp = part_new_empty(builder, content, mime_fields, boundary_prefix, 0);
    if (mp == NULL)
        goto free_content;
    
    return mp;
    
free_content:
    mailmime_content_free(content);
free_fields:
    mailmime_fields_free(mime_fields);
err:
    return NULL;
}

#define MAX_MESSAGE_ID 512

static char * generate_boundary(const char * boundary_prefix)
{
    char id[MAX_MESSAGE_ID];
    time_t now;
    char name[MAX_MESSAGE_ID];
    long value;
    
    now = time(NULL);
    value = random();
    
    gethostname(name, MAX_MESSAGE_ID);
    
    if (boundary_prefix == NULL)
        boundary_prefix = "";
    
    snprintf(id, MAX_MESSAGE_ID, "%s%lx_%lx_%x", boundary_prefix, now, value, getpid());
    
    return strdup(id);
}

void MessageBuilder::init()
{
    mHTMLBody = NULL;
    mTextBody = NULL;
    mAttachments = NULL;
    mRelatedAttachments = NULL;
    mBoundaryPrefix = NULL;
    mBoundaries = new Array();
    mCurrentBoundaryIndex = 0;
}

MessageBuilder::MessageBuilder()
{
    init();
}

MessageBuilder::MessageBuilder(MessageBuilder * other) : AbstractMessage(other)
{
    init();
    setHTMLBody(other->mHTMLBody);
    setTextBody(other->mTextBody);
    setAttachments(other->mAttachments);
    setRelatedAttachments(other->mRelatedAttachments);
    MC_SAFE_REPLACE_COPY(String, mBoundaryPrefix, other->mBoundaryPrefix);
}

MessageBuilder::~MessageBuilder()
{
    MC_SAFE_RELEASE(mHTMLBody);
    MC_SAFE_RELEASE(mTextBody);
    MC_SAFE_RELEASE(mAttachments);
    MC_SAFE_RELEASE(mRelatedAttachments);
    MC_SAFE_RELEASE(mBoundaryPrefix);
    MC_SAFE_RELEASE(mBoundaries);
}
    
String * MessageBuilder::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p\n", className()->UTF8Characters(), this);
    if (header() != NULL) {
        result->appendString(header()->description());
        result->appendUTF8Characters("\n");
    }
    if (mHTMLBody != NULL) {
        result->appendUTF8Characters("-- html body --\n");
        result->appendString(mHTMLBody);
        result->appendUTF8Characters("\n");
    }
    if (mTextBody != NULL) {
        result->appendUTF8Characters("-- text body --\n");
        result->appendString(mTextBody);
        result->appendUTF8Characters("\n");
    }
    if (mAttachments != NULL) {
        result->appendUTF8Characters("-- attachments --\n");
        result->appendString(mAttachments->description());
        result->appendUTF8Characters("\n");
    }
    if (mRelatedAttachments != NULL) {
        result->appendUTF8Characters("-- related attachments --\n");
        result->appendString(mRelatedAttachments->description());
        result->appendUTF8Characters("\n");
    }
    result->appendUTF8Characters(">");
    
    return result;
}

Object * MessageBuilder::copy()
{
    return new MessageBuilder(this);
}

void MessageBuilder::setHTMLBody(String * htmlBody)
{
    MC_SAFE_REPLACE_COPY(String, mHTMLBody, htmlBody);
}

String * MessageBuilder::htmlBody()
{
    return mHTMLBody;
}

void MessageBuilder::setTextBody(String * textBody)
{
    MC_SAFE_REPLACE_COPY(String, mTextBody, textBody);
}

String * MessageBuilder::textBody()
{
    return mTextBody;
}

void MessageBuilder::setAttachments(Array * attachments)
{
    MC_SAFE_REPLACE_COPY(Array, mAttachments, attachments);
}

Array * MessageBuilder::attachments()
{
    return mAttachments;
}

void MessageBuilder::addAttachment(Attachment * attachment)
{
    if (attachment == NULL) {
        return;
    }
    if (mAttachments == NULL) {
        mAttachments = new Array();
    }
    mAttachments->addObject(attachment);
}

void MessageBuilder::setRelatedAttachments(Array * attachments)
{
    MC_SAFE_REPLACE_COPY(Array, mRelatedAttachments, attachments);
}

Array * MessageBuilder::relatedAttachments()
{
    return mRelatedAttachments;
}

void MessageBuilder::addRelatedAttachment(Attachment * attachment)
{
    if (attachment == NULL) {
        return;
    }
    if (mRelatedAttachments == NULL) {
        mRelatedAttachments = new Array();
    }
    mRelatedAttachments->addObject(attachment);
}

void MessageBuilder::setBoundaryPrefix(String * boundaryPrefix)
{
    MC_SAFE_REPLACE_COPY(String, mBoundaryPrefix, boundaryPrefix);
}

String * MessageBuilder::boundaryPrefix()
{
    return mBoundaryPrefix;
}

struct mailmime * MessageBuilder::mimeAndFilterBccAndForEncryption(bool filterBcc, bool forEncryption)
{
    struct mailmime * htmlPart;
    struct mailmime * textPart;
    struct mailmime * altPart;
    struct mailmime * mainPart;
    
    mCurrentBoundaryIndex = 0;
    htmlPart = NULL;
    textPart = NULL;
    altPart = NULL;
    mainPart = NULL;
    
    if (htmlBody() != NULL) {
        Attachment * htmlAttachment;
        
        htmlAttachment = Attachment::attachmentWithHTMLString(htmlBody());
        htmlPart = multipart_related_from_attachments(this, htmlAttachment, mRelatedAttachments,
                                                      MCUTF8(mBoundaryPrefix), forEncryption);
    }
    
    if (textBody() != NULL) {
        Attachment * textAttachment;
        
        textAttachment = Attachment::attachmentWithText(textBody());
        textPart = mime_from_attachment(this, textAttachment, forEncryption);
    }
    else if (htmlBody() != NULL) {
        Attachment * textAttachment;
        
        textAttachment = Attachment::attachmentWithText(htmlBody()->flattenHTML());
        textPart = mime_from_attachment(this, textAttachment, forEncryption);
    }
    
    if ((textPart != NULL) && (htmlPart != NULL)) {
        altPart = get_multipart_alternative(this, MCUTF8(mBoundaryPrefix));
        mailmime_smart_add_part(altPart, textPart);
        mailmime_smart_add_part(altPart, htmlPart);
        mainPart = altPart;
    }
    else if (textPart != NULL) {
        mainPart = textPart;
    }
    else if (htmlPart != NULL) {
        mainPart = htmlPart;
    }
    
    struct mailimf_fields * fields;
    unsigned int i;
    struct mailmime * mime;
    
    fields = header()->createIMFFieldsAndFilterBcc(filterBcc);
    
    mime = mailmime_new_message_data(NULL);
    mailmime_set_imf_fields(mime, fields);
    
    if (mainPart != NULL) {
        add_attachment(this, mime, mainPart, MCUTF8(mBoundaryPrefix));
    }
    
    if (attachments() != NULL) {
        for(i = 0 ; i < attachments()->count() ; i ++) {
            Attachment * attachment;
            struct mailmime * submime;
            
            attachment = (Attachment *) attachments()->objectAtIndex(i);
            submime = mime_from_attachment(this, attachment, forEncryption);
            add_attachment(this, mime, submime, MCUTF8(mBoundaryPrefix));
        }
    }
    
    struct mailmime * result = mime;
    if (forEncryption) {
        result = mime->mm_data.mm_message.mm_msg_mime;
        mime->mm_data.mm_message.mm_msg_mime = NULL;
        mailmime_free(mime);
    }
    
    return result;
}

Data * MessageBuilder::dataAndFilterBccAndForEncryption(bool filterBcc, bool forEncryption)
{
    Data * data;
    MMAPString * str;
    int col;
    
    str = mmap_string_new("");
    col = 0;
    struct mailmime * mime = mimeAndFilterBccAndForEncryption(filterBcc, forEncryption);
    mailmime_write_mem(str, &col, mime);
    data = Data::dataWithBytes(str->str, (unsigned int) str->len);
    mmap_string_free(str);
    mailmime_free(mime);
    
    return data;
}

Data * MessageBuilder::data()
{
    return dataAndFilterBccAndForEncryption(false, false);
}

Data * MessageBuilder::dataForEncryption()
{
    return dataAndFilterBccAndForEncryption(false, true);
}

ErrorCode MessageBuilder::writeToFile(String * filename)
{
    FILE * f = fopen(filename->fileSystemRepresentation(), "wb");
    if (f == NULL) {
        return ErrorFile;
    }

    ErrorCode error = ErrorNone;
    struct mailmime * mime = mimeAndFilterBccAndForEncryption(false, false);

    int col = 0;
    int r = mailmime_write_file(f, &col, mime);
    if (r != MAILIMF_NO_ERROR) {
        error = ErrorFile;
    }

    mailmime_free(mime);

    if (fclose(f) != 0) {
        error = ErrorFile;
    }

    return error;
}

String * MessageBuilder::htmlRendering(HTMLRendererTemplateCallback * htmlCallback)
{
    MessageParser * message = MessageParser::messageParserWithData(data());
    return message->htmlRendering(htmlCallback);
}

String * MessageBuilder::htmlBodyRendering()
{
    MessageParser * message = MessageParser::messageParserWithData(data());
    return message->htmlBodyRendering();
}

String * MessageBuilder::plainTextRendering()
{
    MessageParser * message = MessageParser::messageParserWithData(data());
    return message->plainTextRendering();
}

String * MessageBuilder::plainTextBodyRendering(bool stripWhitespace)
{
    MessageParser * message = MessageParser::messageParserWithData(data());
    return message->plainTextBodyRendering(stripWhitespace);
}

struct mailmime * get_signature_part(Data * signature)
{
    struct mailmime * mime;
    struct mailmime_content * content;
    
    content = mailmime_content_new_with_str("application/pgp-signature");
    struct mailmime_fields * mime_fields = mailmime_fields_new_empty();
    mime = part_new_empty(NULL, content, mime_fields, NULL, 1);
    mailmime_set_body_text(mime, signature->bytes(), signature->length());
    
    return mime;
}

Data * MessageBuilder::openPGPSignedMessageDataWithSignatureData(Data * signature)
{
    struct mailimf_fields * fields;
    struct mailmime * mime;
    
    fields = header()->createIMFFieldsAndFilterBcc(false);
    
    mime = mailmime_new_message_data(NULL);
    mailmime_set_imf_fields(mime, fields);
    
    struct mailmime * multipart = get_multipart_signed_pgp(NULL, MCUTF8(boundaryPrefix()));
    add_attachment(NULL, mime, multipart, MCUTF8(boundaryPrefix()));
    struct mailmime * part_to_sign = mimeAndFilterBccAndForEncryption(false, true);
    add_attachment(NULL, multipart, part_to_sign, MCUTF8(boundaryPrefix()));
    struct mailmime * signature_part = get_signature_part(signature);
    add_attachment(NULL, multipart, signature_part, MCUTF8(boundaryPrefix()));
    
    MMAPString * str = mmap_string_new("");
    int col = 0;
    
    mailmime_write_mem(str, &col, mime);
    Data * data = Data::dataWithBytes(str->str, (unsigned int) str->len);
    mmap_string_free(str);
    mailmime_free(mime);
    
    return data;
}

static struct mailmime * get_pgp_version_part(void)
{
    struct mailmime * mime;
    struct mailmime_content * content;
    
    content = mailmime_content_new_with_str("application/pgp-encrypted");
    struct mailmime_fields * mime_fields = mailmime_fields_new_empty();
    mime = part_new_empty(NULL, content, mime_fields, NULL, 1);
    const char * version = "Version: 1\r\n";
    mailmime_set_body_text(mime, (char *) version, strlen(version));
    
    return mime;
}

static struct mailmime * get_encrypted_part(Data * encryptedData)
{
    struct mailmime * mime;
    struct mailmime_content * content;
    
    content = mailmime_content_new_with_str("application/octet-stream");
    struct mailmime_fields * mime_fields = mailmime_fields_new_empty();
    mime = part_new_empty(NULL, content, mime_fields, NULL, 1);
    mailmime_set_body_text(mime, encryptedData->bytes(), encryptedData->length());
    
    return mime;
}

Data * MessageBuilder::openPGPEncryptedMessageDataWithEncryptedData(Data * encryptedData)
{
    struct mailimf_fields * fields;
    struct mailmime * mime;
    
    fields = header()->createIMFFieldsAndFilterBcc(false);
    
    mime = mailmime_new_message_data(NULL);
    mailmime_set_imf_fields(mime, fields);
    
    struct mailmime * multipart = get_multipart_encrypted_pgp(NULL, MCUTF8(boundaryPrefix()));
    add_attachment(NULL, mime, multipart, MCUTF8(boundaryPrefix()));
    
    struct mailmime * version_part = get_pgp_version_part();
    add_attachment(NULL, multipart, version_part, MCUTF8(boundaryPrefix()));
    struct mailmime * encrypted_part = get_encrypted_part(encryptedData);
    add_attachment(NULL, multipart, encrypted_part, MCUTF8(boundaryPrefix()));
    
    MMAPString * str = mmap_string_new("");
    int col = 0;
    
    mailmime_write_mem(str, &col, mime);
    Data * data = Data::dataWithBytes(str->str, (unsigned int) str->len);
    mmap_string_free(str);
    mailmime_free(mime);
    
    return data;
}

String * MessageBuilder::nextBoundary()
{
    unsigned int idx = mCurrentBoundaryIndex;
    mCurrentBoundaryIndex ++;
    if (idx < mBoundaries->count()) {
        return (String *) mBoundaries->objectAtIndex(idx);
    }
    
    char * boundary = generate_boundary(MCUTF8(mBoundaryPrefix));
    String * boundaryString = String::stringWithUTF8Characters(boundary);
    mBoundaries->addObject(boundaryString);
    free(boundary);
    
    return boundaryString;
}

void MessageBuilder::resetBoundaries()
{
    mBoundaries->removeAllObjects();
}

void MessageBuilder::setBoundaries(Array * boundaries)
{
    resetBoundaries();
    mBoundaries->addObjectsFromArray(boundaries);
}
