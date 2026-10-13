#pragma once
#include <cstddef>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>
#include "json.hpp"

extern std::map<std::string, std::string> g_answers;

namespace UI {
    void welcome_screen();
    bool sudo_prompt();

    std::string action_select();

    // The typed shape every menu consumer reads. menu.json is parsed into this
    // exactly once, in one pass that also seeds the answers.
    struct MenuItem {
        std::string type = "action";
        std::string title;
        std::string id;
        std::string help;
        std::vector<std::string> options;
        std::unordered_map<std::string, int> option_index; // option -> index into options
        std::vector<MenuItem> items;                       // parsed children of a submenu
    };

    std::vector<MenuItem> parse_menu(const nlohmann::json& menu_items);

    bool render_menu(const std::vector<MenuItem>& items, const std::string& title);

    bool review_screen();

    void log_view(const std::string& log_path);

    struct LogViewState {
        bool redraw = true;   // force a full redraw on the next tick
        long last_size = -1;  // install.log size at the last parse
        std::vector<std::string> lines;   // ANSI-stripped log lines
        std::vector<size_t> issues;       // indices of lines with [WARN]/[ERR]
        long view_top = 0;    // index of the first visible line
        bool follow = true;   // auto-scroll to the newest line
    };

    void log_view_tick(const std::string& log_path, LogViewState& state);

    bool log_view_key(const std::string& key, LogViewState& state);

    void complete_screen();
}
