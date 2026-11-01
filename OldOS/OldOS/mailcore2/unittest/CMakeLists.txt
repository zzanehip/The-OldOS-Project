include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}/../src/include
    ${GLIB2_INCLUDE_DIRS}
)

link_directories(
    ${additional_lib_searchpath}
)

add_executable (unittestcpp unittest.cpp)
target_link_libraries (
    unittestcpp MailCore
    ${ZLIB_LIBRARY} ${LIBETPAN_LIBRARY} ${LIBXML_LIBRARY} ${UCHARDET_LIBRARY} sasl2
    ${TIDY_LIBRARY} ${CTEMPLATE_LIBRARY} ssl crypto ${linux_libraries} ${mac_libraries}
    ${GLIB2_LIBRARIES} ${FOUNDATIONFRAMEWORK} ${SECURITYFRAMEWORK} ${CORESERVICESFRAMEWORK}
)
