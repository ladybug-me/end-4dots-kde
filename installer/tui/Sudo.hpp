#pragma once
#include <string>

namespace Sudo {
    // Prepares the askpass helper and the sudo shim the step scripts run through,
    // and takes the idle inhibitor for the length of the install.
    bool prepare(const std::string& password);

    // Removes the shim directory and the password file inside it.
    void cleanup();
}
