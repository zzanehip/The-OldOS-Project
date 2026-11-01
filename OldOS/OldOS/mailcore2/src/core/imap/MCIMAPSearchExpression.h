#ifndef MAILCORE_MCIMAPSEARCHEXPRESSION_H

#define MAILCORE_MCIMAPSEARCHEXPRESSION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPSearchExpression : public Object {
    public:
        IMAPSearchExpression();
        virtual ~IMAPSearchExpression();
        
        virtual IMAPSearchKind kind();
        virtual String * header();
        virtual String * value();
        virtual uint64_t longNumber();
        virtual time_t date();
        virtual IndexSet * uids();
        virtual IndexSet * numbers();
        
        
        virtual IMAPSearchExpression * leftExpression();
        virtual IMAPSearchExpression * rightExpression();
        
        static IMAPSearchExpression * searchAll();
        static IMAPSearchExpression * searchFrom(String * value);
        static IMAPSearchExpression * searchTo(String *value);
        static IMAPSearchExpression * searchCc(String *value);
        static IMAPSearchExpression * searchBcc(String *value);
        static IMAPSearchExpression * searchRecipient(String * value);
        static IMAPSearchExpression * searchSubject(String * value);
        static IMAPSearchExpression * searchContent(String * value);
        static IMAPSearchExpression * searchBody(String * value);
        static IMAPSearchExpression * searchHeader(String * header, String * value);
        static IMAPSearchExpression * searchUIDs(IndexSet * uids);
        static IMAPSearchExpression * searchNumbers(IndexSet * numbers);
        static IMAPSearchExpression * searchRead();
        static IMAPSearchExpression * searchUnread();
        static IMAPSearchExpression * searchFlagged();
        static IMAPSearchExpression * searchUnflagged();
        static IMAPSearchExpression * searchAnswered();
        static IMAPSearchExpression * searchUnanswered();
        static IMAPSearchExpression * searchDraft();
        static IMAPSearchExpression * searchUndraft();
        static IMAPSearchExpression * searchDeleted();
        static IMAPSearchExpression * searchSpam();
        static IMAPSearchExpression * searchBeforeDate(time_t date);
        static IMAPSearchExpression * searchOnDate(time_t date);
        static IMAPSearchExpression * searchSinceDate(time_t date);
        static IMAPSearchExpression * searchBeforeReceivedDate(time_t date);
        static IMAPSearchExpression * searchOnReceivedDate(time_t date);
        static IMAPSearchExpression * searchSinceReceivedDate(time_t date);
        static IMAPSearchExpression * searchSizeLarger(uint32_t size);
        static IMAPSearchExpression * searchSizeSmaller(uint32_t size);
        static IMAPSearchExpression * searchGmailThreadID(uint64_t number);
        static IMAPSearchExpression * searchGmailMessageID(uint64_t number);
        static IMAPSearchExpression * searchGmailRaw(String * expr);
        static IMAPSearchExpression * searchAnd(IMAPSearchExpression * left, IMAPSearchExpression * right);
        static IMAPSearchExpression * searchOr(IMAPSearchExpression * left, IMAPSearchExpression * right);
        static IMAPSearchExpression * searchNot(IMAPSearchExpression * notExpr);
        
        
    public: // subclass behavior
        IMAPSearchExpression(IMAPSearchExpression * other);
        virtual String * description();
        virtual Object * copy();
        
    private:
        IMAPSearchKind mKind;
        String * mHeader;
        String * mValue;
        uint64_t mLongNumber;
        IndexSet * mUids;
        IndexSet * mNumbers;
        IMAPSearchExpression * mLeftExpression;
        IMAPSearchExpression * mRightExpression;
        void init();
    };
    
}

#endif

#endif
