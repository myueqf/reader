using Json;
using Gee;

namespace Reader {
    public class Book : GLib.Object {
        public string name { get; set; }
        public string author { get; set; }
        public string files { get; set; }
        public string cover { get; set; }
        public string chapter_pattern { get; set; }
        public int chapter { get; set; }
        public int page_index { get; set; }
        public string directory { get; set; }
        public string uuid { get; set; }
        
        private string _content;
        private ArrayList<Chapter> _chapters;
        
        public Book () {
            name = "";
            author = "";
            files = "";
            cover = "";
            chapter_pattern = "第\\d+章";
            chapter = 0;
            page_index = 0;
            directory = "";
            uuid = GLib.Uuid.string_random ();
            _chapters = new ArrayList<Chapter> ();
        }

        public Book.from_json (Json.Node node, string dir) {
            directory = dir;
            _chapters = new ArrayList<Chapter> ();
            
            try {
                var obj = node.get_object ();
                
                // 验证下必要字段QWQ
                if (!obj.has_member ("name") || !obj.has_member ("author") || !obj.has_member ("files")) {
                    throw new IOError.INVALID_DATA ("缺少必要的配置字段QWQ");
                }
                
                name = obj.get_string_member ("name");
                author = obj.get_string_member ("author");
                files = obj.get_string_member ("files");
                cover = obj.has_member ("cover") ? obj.get_string_member ("cover") : "";
                chapter_pattern = obj.has_member ("chapterPattern") ? obj.get_string_member ("chapterPattern") : "第\\d+章";
                chapter = obj.has_member ("chapter") ? (int) obj.get_int_member ("chapter") : 0;
                page_index = obj.has_member ("page_index") ? (int) obj.get_int_member ("page_index") : 0;

                // 验证数据的有效性QWQ
                /*
                if (name.strip () == "") {
                    throw new IOError.INVALID_DATA ("书名是空的XwX");
                }
                
                if (files.strip () == "") {
                    throw new IOError.INVALID_DATA ("文件路径不能为空");
                }
                */

                if (uuid.strip () == "" || !obj.has_member ("uuid")) {
                    warning ("UUID是空的QWQ");
                    uuid = GLib.Uuid.string_random ();
                    // uuid = "233";
                }

                /*
                if (uuid.strip () == "233") {
                    warning ("233～");
                    uuid = GLib.Uuid.string_random ();
                }
                */

                load_content ();
                parse_chapters ();
            } catch (Error e) {
                warning ("加载书籍配置失败XwX: %s", e.message);

                name = "未知书籍";
                author = "未知作者";
                files = "config.json"; // 有什么问题自己康XwX
                cover = "";
                chapter_pattern = "第\\d+章";
                chapter = 0;
                page_index = 0;
                uuid = "233";
            }
        }
        
        public Json.Node to_json () {
            var obj = new Json.Object ();
            obj.set_string_member ("name", name);
            obj.set_string_member ("author", author);
            obj.set_string_member ("files", files);
            obj.set_string_member ("cover", cover);
            obj.set_string_member ("chapterPattern", chapter_pattern);
            obj.set_int_member ("chapter", chapter);
            obj.set_int_member ("page_index", page_index);
            obj.set_string_member ("uuid", uuid);
            
            var node = new Json.Node (Json.NodeType.OBJECT);
            node.set_object (obj);
            return node;
        }
        
        public void load_content () {
            if (files == "") {
                warning ("不能加载内容XwX：路径是空的");
                _content = "";
                return;
            }
            
            try {
                var file_path = GLib.Path.build_filename (directory, files);
                var file = File.new_for_path (file_path);
                
                if (!file.query_exists ()) {
                    warning ("文件不存在XwX: %s", file_path);
                    _content = "";
                    return;
                }
                
                uint8[] data;
                file.load_contents (null, out data, null);
                
                // 文件大小限制
                /*
                if (data.length > 10 * 1024 * 1024) {
                    warning ("文件过大，只读取前 10MB");
                    uint8[] truncated = new uint8[10 * 1024 * 1024];
                    Memory.copy (truncated, data, truncated.length);
                    _content = (string) truncated;
                } else {
                    _content = (string) data;
                }
                */
                _content = (string) data;
                
                // 确保内容是有效的 UTF-8
                if (!_content.validate ()) {
                    _content = _content.make_valid ();
                }
                
                if (_content.strip () == "") {
                    warning ("文件内容为空: %s", file_path);
                }
                
            } catch (Error e) {
                warning ("内容被猫猫刁走了: %s", e.message);
                _content = "";
            }
        }
        
        public void parse_chapters () {
            if (_content == "") {
                warning ("无法解析章节XwX：内容是空的");
                return;
            }
            
            if (chapter_pattern.strip () == "") {
            // 如果匹配章节的表达式是空的就用默认（
                chapter_pattern = "第\\d+章";
            }
            
            _chapters.clear ();
            
            try {
                var regex = new Regex (chapter_pattern);
                MatchInfo match_info;
                
                var lines = _content.split ("\n");
                var current_chapter = new Chapter ();
                current_chapter.title = "简介";
                current_chapter.index = 0;
                current_chapter.content = "";
                current_chapter.start_line = 0;
                
                int chapter_count = 0;
                
                // 限制处理的行数，避免无限循环
                int max_lines = int.min (lines.length, 50000);
                
                for (int i = 0; i < max_lines; i++) {
                    var line = lines[i];
                    
                    if (regex.match (line, 0, out match_info)) {
                        if (current_chapter.content.strip () != "") {
                            _chapters.add (current_chapter);
                        }

                        chapter_count++;
                        current_chapter = new Chapter ();
                        current_chapter.title = line.strip ();
                        current_chapter.index = chapter_count;
                        current_chapter.content = "";
                        current_chapter.start_line = i;
                    } else {
                        current_chapter.content += line + "\n";
                    }
                }

                // 添加最后一章
                if (current_chapter.content.strip () != "") {
                    _chapters.add (current_chapter);
                }

                if (_chapters.size == 1) {
                    var single_chapter = new Chapter ();
                    current_chapter.title = name;
                    single_chapter.split_into_pages ();
                }
                
                // 对所有章节进行分页
                foreach (var chapter in _chapters) {
                    chapter.split_into_pages ();
                }
                
            } catch (RegexError e) {
                warning ("解析章节失败XwX: %s", e.message);
                _chapters.clear ();
                var single_chapter = new Chapter ();
                single_chapter.split_into_pages ();
            }
        }
        
        public ArrayList<Chapter> get_chapters () {
            return _chapters;
        }
        
        public Chapter? get_chapter_by_index (int index) {
            if (index < 0 || index >= _chapters.size) {
                return null;
            }
            return _chapters[index];
        }
        
        public string get_cover_path () {
            if (cover == "") {
                return "resource:///io/github/myueqf/reader/default-cover.png";
            }
            return GLib.Path.build_filename (directory, cover);
        }
        
        public double get_progress () {
            return _chapters.size <= 1 ? 0.0 : 
                   (double) chapter.clamp (0, _chapters.size - 1) / (_chapters.size - 1);
        }
        
        public string get_progress_text () {
            if (_chapters.size <= 1) return "0%";
            var progress = get_progress () * 100;
            return "%.0f%% (%d/%d)".printf (progress, chapter.clamp (0, _chapters.size - 1) + 1, _chapters.size);
        }
    }
    
    public class Chapter : GLib.Object {
        public string title { get; set; }
        public int index { get; set; }
        public string content { get; set; }
        public int start_line { get; set; }
        public int total_pages { get; set; }
        public bool is_paginated { get; set; }
        
        private ArrayList<string> _pages;
        private const int MAX_CHARS_PER_PAGE = 5000; // 限制5千字符，防止卡死UI嗷XwX
        
        public Chapter () {
            title = "";
            index = 0;
            content = "";
            start_line = 0;
            total_pages = 1;
            is_paginated = false;
            _pages = new ArrayList<string> ();
        }
        
        public void split_into_pages () {
            _pages.clear ();
            
            if (content.length <= MAX_CHARS_PER_PAGE) {
                _pages.add (content);
                total_pages = 1;
                is_paginated = false;
                return;
            }
            
            is_paginated = true;
            var remaining_content = content;
            var page_count = 0;
            var previous_length = remaining_content.length;
            
            while (remaining_content.length > 0) {
                if (remaining_content.length <= MAX_CHARS_PER_PAGE) {
                    _pages.add (remaining_content);
                    break;
                }
                
                var split_point = find_split_point (remaining_content, MAX_CHARS_PER_PAGE);
                
                if (split_point <= 0 || split_point >= remaining_content.length) {
                    split_point = int.min (MAX_CHARS_PER_PAGE, remaining_content.length);
                }
                
                var page_content = remaining_content.substring (0, split_point);
                _pages.add (page_content);
                
                remaining_content = remaining_content.substring (split_point);
                page_count++;

                // 打印分页进度～
                if (page_count % 50 == 0 && page_count > 0) {
                    var progress = (double)(content.length - remaining_content.length) / content.length * 100;
                    int bar_length = 20;
                    int filled_chars = (int) (progress / 100 * bar_length);
                    int empty_chars = bar_length - filled_chars;
                    string filled_part = "";
                    for (int i = 0; i < filled_chars; i++) {
                        filled_part += "=";
                    }

                    string empty_part = "";
                    for (int i = 0; i < empty_chars; i++) {
                        empty_part += " ";
                    }

                    string progress_bar = "[" + filled_part + ">" + empty_part + "]";
                    print ("分页:%d页%s%.1f%%\n", page_count, progress_bar, progress);
                }

                /*
                if (remaining_content.length >= previous_length) {
                    warning ("分页没有进展，强制分割");
                    if (remaining_content.length > MAX_CHARS_PER_PAGE) {
                        _pages.add (remaining_content.substring (0, MAX_CHARS_PER_PAGE));
                        remaining_content = remaining_content.substring (MAX_CHARS_PER_PAGE);
                    } else {
                        _pages.add (remaining_content);
                        break;
                    }
                }
                */

                previous_length = remaining_content.length;
                
                // 防止分页过多
                if (page_count > 3700) {
                    warning ("分页太多了QAQ");
                    _pages.add (remaining_content);
                    break;
                }
            }
            
            total_pages = _pages.size;
        }
        
        private int find_split_point (string text, int max_length) {
            if (text.length <= max_length) {
                return text.length;
            }
            
            var search_text = text.substring (0, max_length);
            
            var paragraph_separators = new string[] { "\n\n", "\r\n\r\n" };
            
            foreach (var separator in paragraph_separators) {
                var last_separator_pos = search_text.last_index_of (separator);
                if (last_separator_pos >= 0 && last_separator_pos > max_length * 0.7) {
                    return last_separator_pos + separator.length;
                }
            }
            
            var sentence_endings = new string[] { "”", "。", "！", "？", "..", "!", "?" };
            
            foreach (var ending in sentence_endings) {
                var last_ending_pos = search_text.last_index_of (ending);
                if (last_ending_pos >= 0 && last_ending_pos > max_length * 0.8) {
                    return last_ending_pos + ending.length;
                }
            }
            
            var last_newline = search_text.last_index_of ("\n");
            if (last_newline >= 0 && last_newline > max_length * 0.9) {
                return last_newline + 1;
            }
            
            return int.max (1, max_length);
        }
        
        public string get_page_content (int page_index) {
            if (page_index < 0 || page_index >= _pages.size) {
                return "";
            }
            return _pages[page_index];
        }
        
        public string get_current_content () {
            if (!is_paginated || _pages.size == 0) {
                return content;
            }
            return get_page_content (0);
        }
    }
}
