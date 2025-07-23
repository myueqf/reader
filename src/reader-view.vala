using Gtk;
using Adw;

namespace Reader {
    public class ReaderView : Box {
        private Book? current_book;
        private BookManager book_manager;
        private ConfigManager config_manager;
        
        private Gtk.HeaderBar header_bar;
        private Button back_button;
        private Button toc_button;
        private Button prev_button;
        private Button next_button;
        private Button prev_page_button;
        private Button next_page_button;
        private Label chapter_label;
        private Label page_label;
        
        private ScrolledWindow scrolled_window;
        private Label content_label;
        private Button next_chapter_button;
        private Box content_box;
        private Adw.Clamp width_clamp;
        
        private int current_chapter_index = 0;
        private int current_page_index = 0;
        
        public signal void back_requested ();
        
        public ReaderView (BookManager manager, ConfigManager config) {
            book_manager = manager;
            config_manager = config;
            
            setup_ui ();
            setup_connections ();
        }
        
        private void setup_ui () {
            set_orientation (Orientation.VERTICAL);
            set_spacing (0);
            
            setup_header_bar ();
            setup_content_area ();
        }
        
        private void setup_header_bar () {
            header_bar = new Gtk.HeaderBar ();
            
            back_button = new Button.from_icon_name ("go-previous-symbolic");
            back_button.tooltip_text = "返回";
            back_button.clicked.connect (() => {
                back_requested ();
            });
            header_bar.pack_start (back_button);
            
            toc_button = new Button.from_icon_name ("view-list-symbolic");
            toc_button.tooltip_text = "目录";
            toc_button.clicked.connect (on_toc_clicked);
            header_bar.pack_start (toc_button);
            
            // 章节和分页的切换按钮QWQ
            prev_button = new Button.from_icon_name ("go-up-symbolic");
            prev_button.tooltip_text = "上一章";
            prev_button.clicked.connect (on_prev_chapter);
            header_bar.pack_end (prev_button);
            
            next_button = new Button.from_icon_name ("go-down-symbolic");
            next_button.tooltip_text = "下一章";
            next_button.clicked.connect (on_next_chapter);
            header_bar.pack_end (next_button);
            
            next_page_button = new Button.from_icon_name ("go-next-symbolic");
            next_page_button.tooltip_text = "下一页";
            next_page_button.clicked.connect (on_next_page);
            header_bar.pack_end (next_page_button);
            
            prev_page_button = new Button.from_icon_name ("go-previous-symbolic");
            prev_page_button.tooltip_text = "上一页";
            prev_page_button.clicked.connect (on_prev_page);
            header_bar.pack_end (prev_page_button);

            var title_box = new Box (Orientation.VERTICAL, 2);
            title_box.set_halign (Align.CENTER);
            
            chapter_label = new Label ("");
            chapter_label.add_css_class ("heading");
            
            page_label = new Label ("");
            page_label.add_css_class ("caption");
            
            title_box.append (chapter_label);
            title_box.append (page_label);
            
            header_bar.set_title_widget (title_box);
            
            append (header_bar);
        }
        
        private void setup_content_area () {
            scrolled_window = new ScrolledWindow ();
            scrolled_window.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            scrolled_window.set_vexpand (true);
            
            // 宽度限制（
            width_clamp = new Adw.Clamp ();
            width_clamp.set_maximum_size (800);
            width_clamp.set_tightening_threshold (600);
            
            // 内容
            content_box = new Box (Orientation.VERTICAL, 0);
            content_box.set_margin_top (20);
            content_box.set_margin_bottom (20);
            content_box.set_margin_start (20);
            content_box.set_margin_end (20);
            
            content_label = new Label ("");
            content_label.set_wrap (true);
            content_label.set_wrap_mode (Pango.WrapMode.WORD_CHAR);
            content_label.set_xalign (0);
            content_label.set_yalign (0);
            content_label.set_selectable (true);
            content_label.add_css_class ("reader-content");
            content_label.set_hexpand (true);
            
            next_chapter_button = new Button.with_label ("QWQ");
            /*
			next_chapter_button = new Button.with_label ("QWQ") {
				visible = false
			};
            */

            next_chapter_button.add_css_class ("next-chapter-button");
            next_chapter_button.add_css_class ("suggested-action");
            next_chapter_button.set_halign (Align.CENTER);
            next_chapter_button.set_margin_top (20);
            next_chapter_button.clicked.connect (on_next_button_clicked);
            
            content_box.append (content_label);
            content_box.append (next_chapter_button);
            
            width_clamp.set_child (content_box);
            scrolled_window.set_child (width_clamp);
            append (scrolled_window);
        }
        
        private void setup_connections () {
            config_manager.config_changed.connect (apply_reading_settings);
        }
        
        public void set_book (Book book) {
            if (book == null) {
                return;
            }
            
            try {
                current_book = book;
                current_chapter_index = int.max (0, int.min (book.chapter, book.get_chapters ().size - 1));
                current_page_index = book.page_index;
                
                // 确保内容和章节都加载了XwX
                if (book.get_chapters ().size == 0) {
                    book.load_content ();
                    book.parse_chapters ();
                }
                if (book.get_chapters ().size == 0) {
                    content_label.set_text ("内容被猫猫叼走了QAQ");
                    chapter_label.set_text ("XwX");
                    page_label.set_text ("这里什么也木有。。。");
                    next_chapter_button.set_visible (false);
                    return;
                }
                
                
                var chapter = book.get_chapter_by_index (current_chapter_index);
                if (chapter != null && chapter.is_paginated) {
                    current_page_index = int.max (0, int.min (current_page_index, chapter.total_pages - 1));
                } else {
                    current_page_index = 0;
                }
                
                update_header ();
                load_chapter (current_chapter_index);
                apply_reading_settings ();
            } catch (Error e) {
                warning ("设置书籍时出错: %s", e.message);
                content_label.set_text ("Error: " + e.message);
            }
        }
        
        private void update_header () {
            if (current_book == null) return;
            
            var chapter = current_book.get_chapter_by_index (current_chapter_index);
            if (chapter != null) {
                chapter_label.set_text (chapter.title);
                
                // 信息显示
                if (chapter.is_paginated && chapter.total_pages > 1) {
                    page_label.set_text ("第 %d 页 / 共 %d 页".printf (current_page_index + 1, chapter.total_pages));
                    page_label.set_visible (true);
                } else {
                    page_label.set_visible (false);
                }
            } else {
                chapter_label.set_text (current_book.name);
                page_label.set_visible (false);
            }
            
            var chapters = current_book.get_chapters ();
            
            // 更新章节和分页按钮状态
            prev_button.set_sensitive (current_chapter_index > 0);
            next_button.set_sensitive (current_chapter_index < chapters.size - 1);
            if (chapter != null && chapter.is_paginated) {
                prev_page_button.set_sensitive (current_page_index > 0);
                next_page_button.set_sensitive (current_page_index < chapter.total_pages - 1);
                prev_page_button.set_visible (true);
                next_page_button.set_visible (true);
            } else {
                prev_page_button.set_visible (false);
                next_page_button.set_visible (false);
            }
        }
        
        private void load_chapter (int index) {
            if (current_book == null) return;
            
            var chapter = current_book.get_chapter_by_index (index);
            if (chapter == null) {
                content_label.set_text ("内容被猫猫叼走了QAQ");
                return;
            }
            
            try {
                string page_content;
                if (chapter.is_paginated) {
                    page_content = chapter.get_page_content (current_page_index);
                    if (page_content == "") {
                        current_page_index = 0;
                        page_content = chapter.get_page_content (0);
                    }
                } else {
                        page_content = chapter.content;
                }
                
                content_label.set_text (page_content);
                scrolled_window.get_vadjustment ().set_value (0);
                
                var chapters = current_book.get_chapters ();
                var current_chapter = current_book.get_chapter_by_index (index);
                
                if (current_chapter != null && current_chapter.is_paginated && current_page_index < current_chapter.total_pages - 1) {
                    next_chapter_button.set_label ("下一页");
                    next_chapter_button.set_visible (true);
                } else if (index < chapters.size - 1) {
                    next_chapter_button.set_label ("下一章");
                    next_chapter_button.set_visible (true);
                } else {
                    next_chapter_button.set_visible (false);
                }
                
            } catch (Error e) {
                warning ("加载章节内容失败: %s", e.message);
                content_label.set_text ("加载章节时出现错误");
            }
        }
        
        private void on_next_button_clicked () {
            if (current_book == null) return;
            
            var chapter = current_book.get_chapter_by_index (current_chapter_index);
            
            if (chapter != null && chapter.is_paginated && current_page_index < chapter.total_pages - 1) {
                // 还有下一页，翻页
                on_next_page ();
            } else {
                // 木有下一页了，去下一章
                on_next_chapter ();
            }
        }
        
        private void on_prev_chapter () {
            if (current_book == null) return;
            
            if (current_chapter_index > 0) {
                current_chapter_index--;
                current_page_index = 0;
                save_reading_progress ();
                update_header ();
                load_chapter (current_chapter_index);
                scroll_to_top (); 
            }
        }
        
        private void on_next_chapter () {
            if (current_book == null) return;
            
            var chapters = current_book.get_chapters ();
            if (current_chapter_index < chapters.size - 1) {
                current_chapter_index++;
                current_page_index = 0;
                save_reading_progress ();
                update_header ();
                load_chapter (current_chapter_index);
                scroll_to_top (); 
            }
        }
        
        private void on_toc_clicked () {
            if (current_book == null) return;
            
            var toc_dialog = new ChapterListDialog (get_root () as Gtk.Window, current_book, current_chapter_index);
            toc_dialog.chapter_selected.connect ((index) => {
                current_chapter_index = index;
                current_page_index = 0;
                save_reading_progress ();
                update_header ();
                load_chapter (current_chapter_index);
                scroll_to_top (); 
            });
            toc_dialog.present ();
        }
        
        private void save_reading_progress () {
            if (current_book == null) return;
            
            current_book.chapter = current_chapter_index;
            current_book.page_index = current_page_index;
            book_manager.save_book_config (current_book);
        }
        
        private void scroll_to_top () {
            var vadjustment = scrolled_window.get_vadjustment ();
            vadjustment.set_value (0);

            Idle.add (() => {
                var vadj = scrolled_window.get_vadjustment ();
                vadj.set_value (0);
                vadj.value_changed ();
                return false;
            });

            Timeout.add (10, () => {
                var vadj = scrolled_window.get_vadjustment ();
                vadj.set_value (0);
                vadj.value_changed ();
                return false;
            });
        }
        
        private void on_prev_page () {
            if (current_book == null) return;
            
            var chapter = current_book.get_chapter_by_index (current_chapter_index);
            if (chapter != null && chapter.is_paginated && current_page_index > 0) {
                current_page_index--;
                save_reading_progress ();
                update_header ();
                load_chapter (current_chapter_index);
                scroll_to_top (); 
            }
        }
        
        private void on_next_page () {
            if (current_book == null) return;
            
            var chapter = current_book.get_chapter_by_index (current_chapter_index);
            if (chapter != null && chapter.is_paginated && current_page_index < chapter.total_pages - 1) {
                current_page_index++;
                save_reading_progress ();
                update_header ();
                load_chapter (current_chapter_index);
                scroll_to_top (); 
            }
        }
        
        private void apply_reading_settings () {
            if (current_book == null) return;
            
            try {
                config_manager.apply_theme ();
                
                // 应用主题字体样式和阅读宽度QwQ
                var css_provider = new Gtk.CssProvider ();
                var css = ".reader-content { %s }".printf (config_manager.get_font_css ());
                css_provider.load_from_data (css.data);

                var style_context = content_label.get_style_context ();
                style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                width_clamp.set_maximum_size (config_manager.reading_width);
                width_clamp.set_tightening_threshold ((int)(config_manager.reading_width * 0.8));
                
            } catch (Error e) {
                warning ("应用阅读设置失败: %s", e.message);
            }
        }
    }
}
