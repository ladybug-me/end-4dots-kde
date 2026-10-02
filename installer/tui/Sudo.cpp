#include "Sudo.hpp"

#include "Globals.hpp"

#include <cstdlib>
#include <fcntl.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

using namespace std;

namespace {

bool write_password_file_secure(const string& path, const string& password) {
    int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    if (fd == -1) {
        return false;
    }
    string data = password + "\n";
    ssize_t written = write(fd, data.c_str(), data.size());
    close(fd);
    return written == static_cast<ssize_t>(data.size());
}

bool write_file_excl(const string& path, const string& content, int mode) {
    int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, mode);
    if (fd == -1) {
        return false;
    }
    ssize_t written = write(fd, content.c_str(), content.size());
    close(fd);
    return written == static_cast<ssize_t>(content.size());
}

// Single-quotes a value for one of the generated shell scripts. The shim directory
// comes from XDG_RUNTIME_DIR or from mkdtemp, and a quote in that path would otherwise
// end the string the script thinks it is reading.
string shell_single_quote(const string& value) {
    string quoted = "'";
    for (char c : value) {
        if (c == '\'')
            quoted += "'\\''";
        else
            quoted += c;
    }
    quoted += "'";
    return quoted;
}

// The session runtime directory first: it is 0700, owned by the user, and systemd
// removes it at logout, so an installer that is killed outright cannot leave the
// password file in /tmp until the next boot.
bool make_shim_dir(string& out) {
    vector<string> candidates;
    const char* runtime = getenv("XDG_RUNTIME_DIR");
    if (runtime && runtime[0] == '/') {
        struct stat st;
        if (stat(runtime, &st) == 0 && S_ISDIR(st.st_mode) && st.st_uid == getuid()) {
            candidates.push_back(string(runtime) + "/caelestia-bin.XXXXXX");
        }
    }
    candidates.push_back("/tmp/caelestia-bin.XXXXXX");

    for (const string& tmpl : candidates) {
        vector<char> buf(tmpl.begin(), tmpl.end());
        buf.push_back('\0');
        if (char* dir = mkdtemp(buf.data())) {
            out = dir;
            return true;
        }
    }
    return false;
}

bool write_shim_files(const string& password) {
    const string dir = shell_single_quote(g_sudo_bin_dir);
    const string askpass = "#!/bin/bash\ncat " + dir + "/pass.txt\n";
    const string wrapper = "#!/bin/bash\nexport SUDO_ASKPASS=" + dir +
                           "/askpass.sh\nexec /usr/bin/sudo -A \"$@\"\n";
    return write_password_file_secure(g_sudo_bin_dir + "/pass.txt", password) &&
           write_file_excl(g_sudo_bin_dir + "/askpass.sh", askpass, 0700) &&
           write_file_excl(g_sudo_bin_dir + "/sudo", wrapper, 0700);
}

bool is_systemd_inhibit(pid_t pid) {
    ifstream cmdline("/proc/" + to_string(pid) + "/cmdline", ios::binary);
    string command((istreambuf_iterator<char>(cmdline)), istreambuf_iterator<char>());
    return command.find("systemd-inhibit") != string::npos;
}

void release_kde_inhibit(const string& cookie_file) {
    ifstream cookie(cookie_file);
    string value;
    getline(cookie, value);
    if (value.empty())
        return;
    pid_t child = fork();
    if (child == 0) {
        execlp("qdbus6", "qdbus6", "org.freedesktop.ScreenSaver",
               "/ScreenSaver", "org.freedesktop.ScreenSaver.UnInhibit",
               value.c_str(), static_cast<char*>(nullptr));
        _exit(127);
    }
    if (child > 0)
        waitpid(child, nullptr, 0);
}

bool take_idle_inhibitor() {
    const char* runtime = getenv("XDG_RUNTIME_DIR");
    const char* home = getenv("HOME");
    string state_dir = string(runtime ? runtime : (getenv("XDG_STATE_HOME")
        ? getenv("XDG_STATE_HOME")
        : (home ? string(home) + "/.local/state" : "/tmp"))) + "/caelestia";
    std::error_code state_error;
    std::filesystem::create_directories(state_dir, state_error);
    if (state_error || chmod(state_dir.c_str(), 0700) != 0) {
        return false;
    }
    const string pid_file = state_dir + "/inhibit.pid";
    const string cookie_file = state_dir + "/kde_inhibit.cookie";

    ifstream old_pid(pid_file);
    pid_t pid = 0;
    old_pid >> pid;
    // The file is ours to rewrite, but the pid in it is only a number: never signal
    // this process or its parent, whatever the file says.
    if (pid > 0 && pid != getpid() && pid != getppid() && is_systemd_inhibit(pid))
        kill(pid, SIGKILL);
    release_kde_inhibit(cookie_file);

    pid = fork();
    if (pid == 0) {
        execlp("systemd-inhibit", "systemd-inhibit", "--what=idle:sleep",
               "--who=Caelestia installer", "--why=Installation in progress",
               "bash", "-c", "while :; do sleep 600; done",
               static_cast<char*>(nullptr));
        _exit(127);
    }
    if (pid > 0) {
        ofstream pid_out(pid_file);
        pid_out << pid << '\n';
    }

    int cookie_fd = open(cookie_file.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    pid = fork();
    if (pid == 0) {
        if (cookie_fd >= 0)
            dup2(cookie_fd, STDOUT_FILENO);
        execlp("qdbus6", "qdbus6", "org.freedesktop.ScreenSaver",
               "/ScreenSaver", "org.freedesktop.ScreenSaver.Inhibit",
               "Caelestia installer", "Installation in progress",
               static_cast<char*>(nullptr));
        _exit(127);
    }
    if (cookie_fd >= 0)
        close(cookie_fd);
    if (pid > 0)
        waitpid(pid, nullptr, 0);
    return true;
}

} // anonymous namespace

void Sudo::cleanup() {
    if (g_sudo_bin_dir.empty()) {
        return;
    }
    std::error_code remove_error;
    std::filesystem::remove_all(g_sudo_bin_dir, remove_error);
    if (remove_error) {
        cerr << "[installer] warning: could not remove the sudo shim directory "
             << g_sudo_bin_dir << endl;
    }
    g_sudo_bin_dir.clear();
}

bool Sudo::prepare(const string& password) {
    string dir;
    if (!make_shim_dir(dir)) {
        return false;
    }
    g_sudo_bin_dir = dir;

    if (!write_shim_files(password)) {
        Sudo::cleanup();
        return false;
    }

    // The helper, never the password: an exported password is inherited by every
    // process the install starts, and shows up in /proc/<pid>/environ.
    setenv("SUDO_ASKPASS", (g_sudo_bin_dir + "/askpass.sh").c_str(), 1);

    if (!take_idle_inhibitor()) {
        Sudo::cleanup();
        return false;
    }
    return true;
}
