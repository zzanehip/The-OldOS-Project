# Files to build

set(abstract_files
  core/abstract/MCAbstractMessage.cpp
  core/abstract/MCAbstractMessagePart.cpp
  core/abstract/MCAbstractMultipart.cpp
  core/abstract/MCAbstractPart.cpp
  core/abstract/MCAddress.cpp
  core/abstract/MCMessageHeader.cpp
  core/abstract/MCErrorMessage.cpp
)

IF(APPLE)
  set(basetypes_files_apple
    core/basetypes/MCAutoreleasePoolMac.mm
    core/basetypes/MCMainThreadMac.mm
    core/basetypes/MCObjectMac.mm
    core/basetypes/MCDataMac.mm
    core/rfc822/MCMessageParserMac.mm
  )

  set(zip_files_apple
    core/zip/MCZipMac.mm
  )

  set(core_includes_apple
    "${CMAKE_CURRENT_SOURCE_DIR}/core/basetypes/icu-ucsdet"
    "${CMAKE_CURRENT_SOURCE_DIR}/core/basetypes/icu-ucsdet/include"
  )
ENDIF()

IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(basetypes_files_linux
    core/basetypes/MCMainThreadGTK.cpp
  )
ENDIF()


set(basetypes_files
  core/basetypes/MCArray.cpp
  core/basetypes/MCAssert.c
  core/basetypes/MCAutoreleasePool.cpp
  core/basetypes/MCBase64.c
  core/basetypes/MCConnectionLoggerUtils.cpp
  core/basetypes/MCData.cpp
  core/basetypes/MCDataDecoderUtils.cpp
  core/basetypes/MCDataStreamDecoder.cpp
  core/basetypes/MCHash.cpp
  core/basetypes/MCHashMap.cpp
  core/basetypes/MCHTMLCleaner.cpp
  core/basetypes/MCIndexSet.cpp
  core/basetypes/MCJSON.cpp
  core/basetypes/MCJSONParser.cpp
  core/basetypes/MCLibetpan.cpp
  core/basetypes/MCLog.cpp
  core/basetypes/MCMD5.cpp
  core/basetypes/MCNull.cpp
  core/basetypes/MCObject.cpp
  core/basetypes/MCOperation.cpp
  core/basetypes/MCOperationQueue.cpp
  core/basetypes/MCRange.cpp
  core/basetypes/MCSet.cpp
  core/basetypes/MCString.cpp
  core/basetypes/MCValue.cpp
  core/basetypes/ConvertUTF.c
  ${basetypes_files_apple}
  ${basetypes_files_linux}
)

IF(APPLE)
  set(icu_ucsdet_files
    core/basetypes/icu-ucsdet/cmemory.c
    core/basetypes/icu-ucsdet/csdetect.cpp
    core/basetypes/icu-ucsdet/csmatch.cpp
    core/basetypes/icu-ucsdet/csr2022.cpp
    core/basetypes/icu-ucsdet/csrecog.cpp
    core/basetypes/icu-ucsdet/csrmbcs.cpp
    core/basetypes/icu-ucsdet/csrsbcs.cpp
    core/basetypes/icu-ucsdet/csrucode.cpp
    core/basetypes/icu-ucsdet/csrutf8.cpp
    core/basetypes/icu-ucsdet/cstring.c
    core/basetypes/icu-ucsdet/inputext.cpp
    core/basetypes/icu-ucsdet/uarrsort.c
    core/basetypes/icu-ucsdet/ucln_cmn.cpp
    core/basetypes/icu-ucsdet/ucln_in.cpp
    core/basetypes/icu-ucsdet/ucsdet.cpp
    core/basetypes/icu-ucsdet/udataswp.c
    core/basetypes/icu-ucsdet/uenum.c
    core/basetypes/icu-ucsdet/uinvchar.c
    core/basetypes/icu-ucsdet/umutex.cpp
    core/basetypes/icu-ucsdet/uobject.cpp
    core/basetypes/icu-ucsdet/ustring.cpp
    core/basetypes/icu-ucsdet/utrace.c
  )
ENDIF()

set(imap_files
  core/imap/MCIMAPFolder.cpp
  core/imap/MCIMAPFolderStatus.cpp
  core/imap/MCIMAPIdentity.cpp
  core/imap/MCIMAPMessage.cpp
  core/imap/MCIMAPMessagePart.cpp
  core/imap/MCIMAPMultipart.cpp
  core/imap/MCIMAPNamespace.cpp
  core/imap/MCIMAPNamespaceItem.cpp
  core/imap/MCIMAPPart.cpp
  core/imap/MCIMAPSearchExpression.cpp
  core/imap/MCIMAPSession.cpp
  core/imap/MCIMAPSyncResult.cpp
)

set(pop_files
  core/pop/MCPOPMessageInfo.cpp
  core/pop/MCPOPSession.cpp
)

set(nntp_files
  core/nntp/MCNNTPGroupInfo.cpp
  core/nntp/MCNNTPSession.cpp
)

set(provider_files
  core/provider/MCMailProvider.cpp
  core/provider/MCMailProvidersManager.cpp
  core/provider/MCNetService.cpp
  core/provider/MCAccountValidator.cpp
  core/provider/MCMXRecordResolverOperation.cpp
)

set(renderer_files
  core/renderer/MCAddressDisplay.cpp
  core/renderer/MCDateFormatter.cpp
  core/renderer/MCHTMLBodyRendererTemplateCallback.cpp
  core/renderer/MCHTMLRenderer.cpp
  core/renderer/MCHTMLRendererCallback.cpp
  core/renderer/MCHTMLRendererIMAPDataCallback.cpp
  core/renderer/MCSizeFormatter.cpp
  
)

set(rfc822_files
  core/rfc822/MCAttachment.cpp
  core/rfc822/MCMessageBuilder.cpp
  core/rfc822/MCMessageParser.cpp
  core/rfc822/MCMessagePart.cpp
  core/rfc822/MCMultipart.cpp
)

set(smtp_files
  core/smtp/MCSMTPSession.cpp
)

set(zip_files
  core/zip/MCZip.cpp
  core/zip/MiniZip/ioapi.c
  core/zip/MiniZip/unzip.c
  core/zip/MiniZip/zip.c
  ${zip_files_apple}
)

set(security_files
  core/security/MCCertificateUtils.cpp
)

set(core_files
  ${basetypes_files}
  ${icu_ucsdet_files}
  ${abstract_files}
  ${imap_files}
  ${pop_files}
  ${nntp_files}
  ${renderer_files}
  ${rfc822_files}
  ${security_files}
  ${smtp_files}
  ${zip_files}
)

# Includes for build

set(core_includes
  "${CMAKE_CURRENT_SOURCE_DIR}/core"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/abstract"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/basetypes"
  ${core_includes_apple}
  "${CMAKE_CURRENT_SOURCE_DIR}/core/imap"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/pop"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/nntp"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/provider"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/renderer"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/rfc822"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/security"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/smtp"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/zip"
  "${CMAKE_CURRENT_SOURCE_DIR}/core/zip/MiniZip"
)
