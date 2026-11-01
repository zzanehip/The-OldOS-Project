#ifndef MAILCORE_MCIMAPSESSION_H

#define MAILCORE_MCIMAPSESSION_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>
#include <MailCore/MCIMAPMessage.h>

#ifdef __cplusplus

namespace mailcore {
    
    extern String * IMAPNamespacePersonal;
    extern String * IMAPNamespaceOther;
    extern String * IMAPNamespaceShared;
    
    class IMAPNamespace;
    class IMAPSearchExpression;
    class IMAPFolder;
    class IMAPProgressCallback;
    class IMAPSyncResult;
    class IMAPFolderStatus;
    class IMAPIdentity;
    
    class MAILCORE_EXPORT IMAPSession : public Object {
    public:
        IMAPSession();
        virtual ~IMAPSession();
        
        virtual void setHostname(String * hostname);
        virtual String * hostname();
        
        virtual void setPort(unsigned int port);
        virtual unsigned int port();
        
        virtual void setUsername(String * username);
        virtual String * username();
        
        virtual void setPassword(String * password);
        virtual String * password();
        
        // To authenticate using OAuth2, username and oauth2token should be set.
        // auth type to use is AuthTypeOAuth2.
        virtual void setOAuth2Token(String * token);
        virtual String * OAuth2Token();
        
        virtual void setAuthType(AuthType authType);
        virtual AuthType authType();
        
        virtual void setConnectionType(ConnectionType connectionType);
        virtual ConnectionType connectionType();
        
        virtual void setTimeout(time_t timeout);
        virtual time_t timeout();
        
        virtual void setCheckCertificateEnabled(bool enabled);
        virtual bool isCheckCertificateEnabled();
        
        virtual void setVoIPEnabled(bool enabled);
        virtual bool isVoIPEnabled();
        
        // Needed for fetchSubscribedFolders() and fetchAllFolders().
        virtual void setDefaultNamespace(IMAPNamespace * ns);
        virtual IMAPNamespace * defaultNamespace();
        
        virtual IMAPIdentity * serverIdentity();
        virtual IMAPIdentity * clientIdentity();
        virtual void setClientIdentity(IMAPIdentity * identity);

        virtual void select(String * folder, ErrorCode * pError);
        virtual IMAPFolderStatus * folderStatus(String * folder, ErrorCode * pError);
        
        virtual Array * /* IMAPFolder */ fetchSubscribedFolders(ErrorCode * pError);
        virtual Array * /* IMAPFolder */ fetchAllFolders(ErrorCode * pError); // will use xlist if available
        
        virtual void renameFolder(String * folder, String * otherName, ErrorCode * pError);
        virtual void deleteFolder(String * folder, ErrorCode * pError);
        virtual void createFolder(String * folder, ErrorCode * pError);
        
        virtual void subscribeFolder(String * folder, ErrorCode * pError);
        virtual void unsubscribeFolder(String * folder, ErrorCode * pError);
        
        virtual void appendMessage(String * folder, Data * messageData, MessageFlag flags,
                                   IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError);
        virtual void appendMessageWithCustomFlags(String * folder, Data * messageData, MessageFlag flags, Array * customFlags,
                                   IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError);
        virtual void appendMessageWithCustomFlagsAndDate(String * folder, Data * messageData, MessageFlag flags, Array * customFlags, time_t date,
                                                         IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError);
        virtual void appendMessageWithCustomFlagsAndDate(String * folder, String * messagePath, MessageFlag flags, Array * customFlags, time_t date,
                                                         IMAPProgressCallback * progressCallback, uint32_t * createdUID, ErrorCode * pError);

        virtual void copyMessages(String * folder, IndexSet * uidSet, String * destFolder,
                                  HashMap ** pUidMapping, ErrorCode * pError);
        
        virtual void moveMessages(String * folder, IndexSet * uidSet, String * destFolder,
                                  HashMap ** pUidMapping, ErrorCode * pError);

        virtual void expunge(String * folder, ErrorCode * pError);
        
        virtual Array * /* IMAPMessage */ fetchMessagesByUID(String * folder, IMAPMessagesRequestKind requestKind,
                                                             IndexSet * uids, IMAPProgressCallback * progressCallback,
                                                             ErrorCode * pError);
        virtual Array * /* IMAPMessage */ fetchMessagesByUIDWithExtraHeaders(String * folder,
                                                                             IMAPMessagesRequestKind requestKind,
                                                                             IndexSet * uids,
                                                                             IMAPProgressCallback * progressCallback,
                                                                             Array * extraHeaders, ErrorCode * pError);
        virtual Array * /* IMAPMessage */ fetchMessagesByNumber(String * folder, IMAPMessagesRequestKind requestKind,
                                                                IndexSet * numbers, IMAPProgressCallback * progressCallback,
                                                                ErrorCode * pError);
        virtual Array * /* IMAPMessage */ fetchMessagesByNumberWithExtraHeaders(String * folder,
                                                                                IMAPMessagesRequestKind requestKind,
                                                                                IndexSet * numbers,
                                                                                IMAPProgressCallback * progressCallback,
                                                                                Array * extraHeaders, ErrorCode * pError);
        virtual String * customCommand(String * command, ErrorCode * pError);

        virtual Data * fetchMessageByUID(String * folder, uint32_t uid,
                                         IMAPProgressCallback * progressCallback, ErrorCode * pError);
        virtual Data * fetchMessageByNumber(String * folder, uint32_t number,
                                            IMAPProgressCallback * progressCallback, ErrorCode * pError);
        virtual Data * fetchMessageAttachmentByUID(String * folder, uint32_t uid, String * partID,
                                                   Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError);

        virtual void fetchMessageAttachmentToFileByChunksByUID(String * folder, uint32_t uid, String * partID,
                                                       uint32_t estimatedSize, Encoding encoding,
                                                       String * outputFile, uint32_t chunkSize,
                                                       IMAPProgressCallback * progressCallback, ErrorCode * pError);
        virtual void fetchMessageAttachmentToFileByUID(String * folder, uint32_t uid, String * partID,
                                                       Encoding encoding, String * outputFile,
                                                       IMAPProgressCallback * progressCallback, ErrorCode * pError);

        virtual Data * fetchMessageAttachmentByNumber(String * folder, uint32_t number, String * partID,
                                                      Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError);
        virtual HashMap * fetchMessageNumberUIDMapping(String * folder, uint32_t fromUID, uint32_t toUID,
                                                       ErrorCode * pError);
        
        /* When CONDSTORE or QRESYNC is available */
        virtual IMAPSyncResult * syncMessagesByUID(String * folder, IMAPMessagesRequestKind requestKind,
                                                   IndexSet * uids, uint64_t modseq,
                                                   IMAPProgressCallback * progressCallback, ErrorCode * pError);
        /* Same as syncMessagesByUID, allows for extra headers */
        virtual IMAPSyncResult * syncMessagesByUIDWithExtraHeaders(String * folder, IMAPMessagesRequestKind requestKind,
                                                                   IndexSet * uids, uint64_t modseq,
                                                                   IMAPProgressCallback * progressCallback,
                                                                   Array * extraHeaders, ErrorCode * pError);
        
        virtual void storeFlagsByUID(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, MessageFlag flags, ErrorCode * pError);
        virtual void storeFlagsAndCustomFlagsByUID(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags, ErrorCode * pError);
        virtual void storeFlagsByNumber(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, MessageFlag flags, ErrorCode * pError);
        virtual void storeFlagsAndCustomFlagsByNumber(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags, ErrorCode * pError);
        
        virtual void storeLabelsByUID(String * folder, IndexSet * uids, IMAPStoreFlagsRequestKind kind, Array * labels, ErrorCode * pError);
        virtual void storeLabelsByNumber(String * folder, IndexSet * numbers, IMAPStoreFlagsRequestKind kind, Array * labels, ErrorCode * pError);
        
        virtual IndexSet * search(String * folder, IMAPSearchKind kind, String * searchString, ErrorCode * pError);
        virtual IndexSet * search(String * folder, IMAPSearchExpression * expression, ErrorCode * pError);
        virtual void getQuota(uint32_t *usage, uint32_t *limit, ErrorCode * pError);
        
        virtual bool setupIdle();
        virtual void idle(String * folder, uint32_t lastKnownUID, ErrorCode * pError);
        virtual void interruptIdle();
        virtual void unsetupIdle();
        
        virtual void connect(ErrorCode * pError);
        virtual void disconnect();
        
        virtual void noop(ErrorCode * pError);
        
        virtual HashMap * fetchNamespace(ErrorCode * pError);
        
        virtual void login(ErrorCode * pError);
        
        virtual IMAPIdentity * identity(IMAPIdentity * clientIdentity, ErrorCode * pError);
        
        virtual IndexSet * capability(ErrorCode * pError);
        
        virtual void enableCompression(ErrorCode * pError);
        
        virtual uint32_t uidValidity();
        virtual uint32_t uidNext();
        virtual uint64_t modSequenceValue();
        virtual unsigned int lastFolderMessageCount();
        virtual uint32_t firstUnseenUid();
        
        virtual bool isIdleEnabled();
        virtual bool isXListEnabled();
        virtual bool isCondstoreEnabled();
        virtual bool isQResyncEnabled();
        virtual bool isIdentityEnabled();
        virtual bool isXOAuthEnabled();
        virtual bool isNamespaceEnabled();
        virtual bool isCompressionEnabled();
        virtual bool allowsNewPermanentFlags();
      
        virtual String * gmailUserDisplayName() DEPRECATED_ATTRIBUTE;
        
        virtual void setConnectionLogger(ConnectionLogger * logger);
        virtual ConnectionLogger * connectionLogger();
        
        /** HTML rendering of the body of the message to be displayed in a web view.*/
        virtual String * htmlRendering(IMAPMessage * message, String * folder, ErrorCode * pError);
        
        /** HTML rendering of the body of the message.*/
        virtual String * htmlBodyRendering(IMAPMessage * message, String * folder, ErrorCode * pError);
        
        /** Text rendering of the message.*/
        virtual String * plainTextRendering(IMAPMessage * message, String * folder, ErrorCode * pError);
        
        /** Text rendering of the body of the message. All end of line will be removed and white spaces cleaned up if requested.
         This method can be used to generate the summary of the message.*/
        virtual String * plainTextBodyRendering(IMAPMessage * message, String * folder, bool stripWhitespace, ErrorCode * pError);
        
        /** Enable automatic query of the capabilities of the IMAP server when set to true. */
        virtual void setAutomaticConfigurationEnabled(bool enabled);
        
        /** Check if the automatic query of the capabilities of the IMAP server is enabled. */
        virtual bool isAutomaticConfigurationEnabled();

        virtual String * loginResponse();
        /** Filled by unparsed protocol data in case of ParseError (only for login for now). */
        virtual Data * unparsedResponseData();
        
    public: // private
        virtual void loginIfNeeded(ErrorCode * pError);
        virtual void connectIfNeeded(ErrorCode * pError);
        virtual void selectIfNeeded(String * folder, ErrorCode * pError);
        virtual bool isDisconnected();
        virtual bool isAutomaticConfigurationDone();
        virtual void resetAutomaticConfigurationDone();
        virtual void applyCapabilities(IndexSet * capabilities);
        virtual IndexSet * storedCapabilities();
        virtual void lockConnectionLogger();
        virtual void unlockConnectionLogger();
        virtual ConnectionLogger * connectionLoggerNoLock();

    private:
        String * mHostname;
        unsigned int mPort;
        String * mUsername;
        String * mPassword;
        String * mOAuth2Token;
        AuthType mAuthType;
        ConnectionType mConnectionType;
        bool mCheckCertificateEnabled;
        bool mVoIPEnabled;
        char mDelimiter;
        IMAPNamespace * mDefaultNamespace;
        IMAPIdentity * mServerIdentity;
        IMAPIdentity * mClientIdentity;
        time_t mTimeout;
        
        bool mBodyProgressEnabled;
        bool mIdleEnabled;
        bool mXListEnabled;
        bool mCondstoreEnabled;
        bool mQResyncEnabled;
        bool mXYMHighestModseqEnabled;
        bool mIdentityEnabled;
        bool mXOauth2Enabled;
        bool mNamespaceEnabled;
        bool mCompressionEnabled;
        bool mIsGmail;
        bool mAllowsNewPermanentFlags;
        String * mWelcomeString;
        bool mNeedsMboxMailWorkaround;
        uint32_t mUIDValidity;
        uint32_t mUIDNext;
        uint64_t mModSequenceValue;
        unsigned int mFolderMsgCount;
        uint32_t mFirstUnseenUid;
        bool mYahooServer;
        bool mRamblerRuServer;
        bool mHermesServer;
        bool mQipServer;
        
        unsigned int mLastFetchedSequenceNumber;
        String * mCurrentFolder;
        pthread_mutex_t mIdleLock;
        int mState;
        mailimap * mImap;
        IMAPProgressCallback * mProgressCallback;
        unsigned int mProgressItemsCount;
        ConnectionLogger * mConnectionLogger;
        pthread_mutex_t mConnectionLoggerLock;
        bool mAutomaticConfigurationEnabled;
        bool mAutomaticConfigurationDone;
        bool mShouldDisconnect;
        
        String * mLoginResponse;
        String * mGmailUserDisplayName;
        Data * mUnparsedResponseData;
        
        void init();
        void bodyProgress(unsigned int current, unsigned int maximum);
        void itemsProgress(unsigned int current, unsigned int maximum);
        bool checkCertificate();
        static void body_progress(size_t current, size_t maximum, void * context);
        static void items_progress(size_t current, size_t maximum, void * context);
        void setup();
        void unsetup();
        char fetchDelimiterIfNeeded(char defaultDelimiter, ErrorCode * pError);
        IMAPSyncResult * fetchMessages(String * folder, IMAPMessagesRequestKind requestKind,
                                       bool fetchByUID, struct mailimap_set * imapset,
                                       IndexSet * uidsFilter, IndexSet * numbersFilter,
                                       uint64_t modseq,
                                       HashMap * mapping, IMAPProgressCallback * progressCallback,
                                       Array * extraHeaders, ErrorCode * pError);
        void capabilitySetWithSessionState(IndexSet * capabilities);
        bool enableFeature(String * feature);
        void enableFeatures();
        Data * fetchMessage(String * folder, bool identifier_is_uid, uint32_t identifier,
                            IMAPProgressCallback * progressCallback, ErrorCode * pError);
        void storeFlagsAndCustomFlags(String * folder, bool identifier_is_uid, IndexSet * identifiers,
                                      IMAPStoreFlagsRequestKind kind, MessageFlag flags, Array * customFlags, ErrorCode * pError);
        Data * fetchMessageAttachment(String * folder, bool identifier_is_uid,
                                      uint32_t identifier, String * partID,
                                      Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError);
        // in case of wholePart is false, receives range [offset, length]
        Data * fetchNonDecodedMessageAttachment(String * folder, bool identifier_is_uid,
                                      uint32_t identifier, String * partID,
                                      bool wholePart, uint32_t offset, uint32_t length,
                                      Encoding encoding, IMAPProgressCallback * progressCallback, ErrorCode * pError);
        void storeLabels(String * folder, bool identifier_is_uid, IndexSet * identifiers, IMAPStoreFlagsRequestKind kind, Array * labels, ErrorCode * pError);
    };

}

#endif

#endif
