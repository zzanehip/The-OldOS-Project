//
//  MCHTMLRendererCallback.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 2/2/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCHTMLRENDERERCALLBACK_H

#define MAILCORE_MCHTMLRENDERERCALLBACK_H

#include <MailCore/MCAbstract.h>
#include <MailCore/MCIMAP.h>
#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MessageParser;
    class Attachment;
    
    class MAILCORE_EXPORT HTMLRendererIMAPCallback {
    public:
        HTMLRendererIMAPCallback() {}
        virtual ~HTMLRendererIMAPCallback() {}

        virtual Data * dataForIMAPPart(String * folder, IMAPPart * part) { return NULL; }
        virtual void prefetchAttachmentIMAPPart(String * folder, IMAPPart * part) {}
        virtual void prefetchImageIMAPPart(String * folder, IMAPPart * part) {}
    };

    class MAILCORE_EXPORT HTMLRendererTemplateCallback {
    public:
        HTMLRendererTemplateCallback();
        virtual ~HTMLRendererTemplateCallback();

        virtual void setMixedTextAndAttachmentsModeEnabled(bool enabled);

        virtual bool canPreviewPart(AbstractPart * part);
        virtual bool shouldShowPart(AbstractPart * part);
        
        virtual HashMap * templateValuesForHeader(MessageHeader * header);
        virtual HashMap * templateValuesForPart(AbstractPart * part);
        
        virtual String * templateForMainHeader(MessageHeader * header);
        virtual String * templateForImage(AbstractPart * part);
        virtual String * templateForAttachment(AbstractPart * part);
        virtual String * templateForMessage(AbstractMessage * message);
        virtual String * templateForEmbeddedMessage(AbstractMessagePart * part);
        virtual String * templateForEmbeddedMessageHeader(MessageHeader * header);
        virtual String * templateForAttachmentSeparator();
        
        virtual String * cleanHTMLForPart(String * html);

        // Can be used to filter some HTML tags.
        virtual String * filterHTMLForPart(String * html);
        
        // Can be used to hide quoted text.
        virtual String * filterHTMLForMessage(String * html);
    };

    class MAILCORE_EXPORT HTMLRendererRFC822Callback {
    public:
        virtual Data * dataForRFC822Part(String * folder, Attachment * part) { return NULL; }

    };
    
}

#endif

#endif
