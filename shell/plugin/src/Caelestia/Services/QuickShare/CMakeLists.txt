set(PROTO_SRCS)
set(PROTO_HDRS)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS
    proto/device_to_device_messages.proto
    proto/offline_wire_formats.proto
    proto/securegcm.proto
    proto/securemessage.proto
    proto/ukey.proto
    proto/wire_format.proto
)

# Quick Share gets its own module rather than a corner of Caelestia.Services: it is
# the only part of the plugin that needs protobuf and OpenSSL, and it exposes a
# single type. Nesting the URI under Caelestia.Services mirrors how Caelestia.Config
# and Caelestia.Settings sit inside the core module's directory.
qml_module(caelestia-quickshare
    URI Caelestia.Services.QuickShare
    SOURCES
        QuickShareDiscovery.cpp
        QuickShareDiscovery.hpp
        QuickShareCrypto.cpp
        QuickShareCrypto.hpp
        QuickShareConnection.cpp
        QuickShareConnection.hpp
        QuickShareEndpointInfo.cpp
        QuickShareEndpointInfo.hpp
        QuickShareProto.hpp
        quickshare_service.cpp
        quickshare_service.hpp
        QuickShareBle.cpp
        QuickShareBle.hpp
        ${PROTO_SRCS}
    LIBRARIES
        Qt::DBus
        Qt::Network
        protobuf::libprotobuf
        OpenSSL::Crypto
        OpenSSL::SSL
)

# protobuf_generate_cpp writes the generated headers into this directory's build
# directory, and the sources include them by bare name.
target_include_directories(caelestia-quickshare PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

# The port the firewall rule is written for is the port bound here. QUICKSHARE_PORT is
# read from shell/scripts/quickshare-port at the plugin root, so the service, the setup
# helper the shell runs and the install step all take it from one place.
target_compile_definitions(caelestia-quickshare PRIVATE CAELESTIA_QUICKSHARE_PORT=${QUICKSHARE_PORT})
