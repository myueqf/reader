using Gtk;
using Adw;

namespace Reader {
    public class BookEditDialog : Adw.Window {
        private Book book;
        private Adw.EntryRow name_entry;
        private Adw.EntryRow author_entry;
        private Adw.EntryRow pattern_entry;
        private Picture cover_picture;
        private Button cover_button;
        private Button save_button;
        private Button cancel_button;
        
        public signal void book_updated (Book book);
        
        public BookEditDialog (Gtk.Window? parent, Book book) {
            Object (
                title: "编辑书籍",
                default_width: 500,
                default_height: 400,
                modal: true,
                transient_for: parent
            );
            
            this.book = book;
            
            setup_ui ();
            load_book_data ();
        }
        
        private void setup_ui () {
            var main_box = new Box (Orientation.VERTICAL, 12);
            main_box.set_margin_top (12);
            main_box.set_margin_bottom (12);
            main_box.set_margin_start (12);
            main_box.set_margin_end (12);



            var header_bar = new Adw.HeaderBar ();
            header_bar.add_css_class ("QWQ");
            header_bar.set_title_widget (new Label ("编辑书籍信息"));
            /*
            cancel_button = new Button.with_label ("取消");
            cancel_button.clicked.connect (() => {
                destroy ();
            });
            */
            header_bar.pack_start (cancel_button);
            
            save_button = new Button.with_label ("保存");
            save_button.add_css_class ("suggested-action");
            save_button.clicked.connect (on_save_clicked);
            header_bar.pack_end (save_button);
            
            main_box.append (header_bar);
            
            var content_box = new Box (Orientation.HORIZONTAL, 20);
            
            setup_cover_section (content_box);
            setup_info_section (content_box);
            
            main_box.append (content_box);
            
            set_content (main_box);
        }
        
        private void setup_cover_section (Box parent) {
            var cover_box = new Box (Orientation.VERTICAL, 8);
            cover_box.set_valign (Align.START);
            
            var cover_label = new Label ("封面");
            cover_label.add_css_class ("heading");
            cover_label.set_xalign (0);
            
            cover_picture = new Picture ();
            cover_picture.set_size_request (120, 160);
            cover_picture.add_css_class ("book-cover");
            
            cover_button = new Button.with_label ("选择封面");
            cover_button.clicked.connect (on_cover_button_clicked);
            
            cover_box.append (cover_label);
            cover_box.append (cover_picture);
            cover_box.append (cover_button);
            
            parent.append (cover_box);
        }
        
        private void setup_info_section (Box parent) {
            var info_box = new Box (Orientation.VERTICAL, 12);
            info_box.set_hexpand (true);
            
            var form_group = new Adw.PreferencesGroup ();
            form_group.set_title ("书籍信息");
            
            var name_row = new Adw.EntryRow ();
            name_row.set_title ("书名");
            name_entry = name_row;
            form_group.add (name_row);
            
            var author_row = new Adw.EntryRow ();
            author_row.set_title ("作者");
            author_entry = author_row;
            form_group.add (author_row);
            
            var pattern_row = new Adw.EntryRow ();
            pattern_row.set_title ("章节匹配表达式");
            pattern_entry = pattern_row;
            form_group.add (pattern_row);
            
            info_box.append (form_group);
            
            parent.append (info_box);
        }
        
        private void load_book_data () {
            name_entry.set_text (book.name);
            author_entry.set_text (book.author);
            pattern_entry.set_text (book.chapter_pattern);
            
            load_cover_image ();
        }
        
        private void load_cover_image () {
            try {
                var cover_path = book.get_cover_path ();
                if (cover_path.has_prefix ("resource://")) {
                    var resource = cover_path.substring (11);
                    var pixbuf = new Gdk.Pixbuf.from_resource_at_scale (resource, 120, 160, false);
                    var texture = Gdk.Texture.for_pixbuf (pixbuf);
                    cover_picture.set_paintable (texture);
                } else {
                    var file = File.new_for_path (cover_path);
                    if (file.query_exists ()) {
                        var pixbuf = new Gdk.Pixbuf.from_file_at_scale (cover_path, 120, 160, false);
                        var texture = Gdk.Texture.for_pixbuf (pixbuf);
                        cover_picture.set_paintable (texture);
                    } else {
                        var pixbuf = new Gdk.Pixbuf.from_resource_at_scale ("/io/github/myueqf/reader/default-cover.png", 120, 160, false);
                        var texture = Gdk.Texture.for_pixbuf (pixbuf);
                        cover_picture.set_paintable (texture);
                    }
                }
            } catch (Error e) {
                warning ("封面加载失败QAQ: %s", e.message);
            }
        }
        
        private void on_cover_button_clicked () {
            var file_chooser = new FileChooserNative (
                "选择图片",
                this,
                FileChooserAction.OPEN,
                "选择",
                "取消"
            );
            
            var filter = new FileFilter ();
            filter.set_filter_name ("图片");
            filter.add_mime_type ("image/jpeg");
            filter.add_mime_type ("image/png");
            filter.add_mime_type ("image/gif");
            filter.add_mime_type ("image/webp");
            file_chooser.add_filter (filter);
            
            file_chooser.response.connect ((response) => {
                if (response == ResponseType.ACCEPT) {
                    var file = file_chooser.get_file ();
                    if (file != null) {
                        try {
                            var dest_path = Path.build_filename (book.directory, "cover" + get_file_extension (file.get_basename ()));
                            var dest_file = File.new_for_path (dest_path);
                            file.copy (dest_file, FileCopyFlags.OVERWRITE);
                            
                            book.cover = dest_file.get_basename ();
                            load_cover_image ();
                        } catch (Error e) {
                            warning ("复制图片失败XwX: %s", e.message);
                        }
                    }
                }
            });
            
            file_chooser.show ();
        }
        
        private string get_file_extension (string filename) {
            var parts = filename.split (".");
            if (parts.length > 1) {
                return "." + parts[parts.length - 1];
            }
            return "";
        }
        
        private void on_save_clicked () {
            book.name = name_entry.get_text ();
            book.author = author_entry.get_text ();
            book.chapter_pattern = pattern_entry.get_text ();
            
            book.parse_chapters ();
            
            book_updated (book);
            destroy ();
        }
    }
}
