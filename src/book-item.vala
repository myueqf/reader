using Gtk;
using Gdk;

namespace Reader {
    public class BookItem : FlowBoxChild {
        private Book book;
        private Box main_box;
        private Picture cover_picture;
        private Label title_label;
        private Label author_label;
        private Label progress_label;
        
        public signal void book_selected (Book book);
        public signal void book_edit_requested (Book book);
        public signal void book_delete_requested (Book book);
        
        public BookItem (Book book) {
            this.book = book;
            
            setup_ui ();
            setup_interactions ();
        }
        
        private void setup_ui () {
            set_size_request (280, 120);
            add_css_class ("book-item");
            
            main_box = new Box (Orientation.HORIZONTAL, 12);
            main_box.set_margin_top (8);
            main_box.set_margin_bottom (8);
            main_box.set_margin_start (8);
            main_box.set_margin_end (8);
            
            setup_cover ();
            setup_info ();
            
            set_child (main_box);
        }
        
        private void setup_cover () {
            cover_picture = new Picture ();
            cover_picture.set_size_request (80, 100);
            cover_picture.add_css_class ("book-cover");
            
            try {
                var cover_path = book.get_cover_path ();
                if (cover_path.has_prefix ("resource://")) {
                    var resource = cover_path.substring (11);
                    var pixbuf = new Gdk.Pixbuf.from_resource_at_scale (resource, 80, 100, false);
                    var texture = Gdk.Texture.for_pixbuf (pixbuf);
                    cover_picture.set_paintable (texture);
                } else {
                    var file = File.new_for_path (cover_path);
                    if (file.query_exists ()) {
                        var pixbuf = new Gdk.Pixbuf.from_file_at_scale (cover_path, 80, 100, false);
                        var texture = Gdk.Texture.for_pixbuf (pixbuf);
                        cover_picture.set_paintable (texture);
                    } else {
                        var pixbuf = new Gdk.Pixbuf.from_resource_at_scale ("/io/github/myueqf/reader/default-cover.png", 80, 100, false);
                        var texture = Gdk.Texture.for_pixbuf (pixbuf);
                        cover_picture.set_paintable (texture);
                    }
                }
            } catch (Error e) {
                try {
                    var pixbuf = new Gdk.Pixbuf.from_resource_at_scale ("/io/github/myueqf/reader/default-cover.png", 80, 100, false);
                    var texture = Gdk.Texture.for_pixbuf (pixbuf);
                    cover_picture.set_paintable (texture);
                } catch (Error err) {
                    warning ("加载封面失败XwX: %s", err.message);
                }
            }
            
            main_box.append (cover_picture);
        }
        
        private void setup_info () {
            var info_box = new Box (Orientation.VERTICAL, 4);
            info_box.set_hexpand (true);
            info_box.set_valign (Align.START);
            
            title_label = new Label (book.name);
            title_label.set_xalign (0);
            title_label.set_ellipsize (Pango.EllipsizeMode.END);
            title_label.set_lines (2);
            title_label.set_wrap (true);
            title_label.set_wrap_mode (Pango.WrapMode.WORD_CHAR);
            title_label.add_css_class ("book-title");
            
            author_label = new Label (book.author);
            author_label.set_xalign (0);
            author_label.set_ellipsize (Pango.EllipsizeMode.END);
            author_label.add_css_class ("book-author");
            
            progress_label = new Label (book.get_progress_text ());
            progress_label.set_xalign (1);
            progress_label.set_halign (Align.END);
            progress_label.set_valign (Align.END);
            progress_label.set_vexpand (true);
            progress_label.add_css_class ("book-progress");
            
            info_box.append (title_label);
            info_box.append (author_label);
            info_box.append (progress_label);
            
            main_box.append (info_box);
        }
        
        private void setup_interactions () {
            var click_gesture = new GestureClick ();
            click_gesture.pressed.connect ((n_press, x, y) => {
                if (n_press == 1) {
                    book_selected (book);
                }
            });
            add_controller (click_gesture);
            
            var right_click_gesture = new GestureClick ();
            right_click_gesture.set_button (3);
            right_click_gesture.pressed.connect ((n_press, x, y) => {
                if (n_press == 1) {
                    show_context_menu (x, y);
                }
            });
            add_controller (right_click_gesture);
        }
        
        private void show_context_menu (double x, double y) {
            var menu = new PopoverMenu.from_model (null);
            
            var menu_model = new Menu ();
            menu_model.append ("编辑", "book.edit");
            menu_model.append ("删除", "book.delete");
            
            var action_group = new SimpleActionGroup ();
            
            var edit_action = new SimpleAction ("edit", null);
            edit_action.activate.connect (() => {
                book_edit_requested (book);
                menu.popdown ();
            });
            action_group.add_action (edit_action);
            
            var delete_action = new SimpleAction ("delete", null);
            delete_action.activate.connect (() => {
                book_delete_requested (book);
                menu.popdown ();
            });
            action_group.add_action (delete_action);
            
            insert_action_group ("book", action_group);
            
            menu.set_menu_model (menu_model);
            menu.set_parent (this);
            menu.set_pointing_to ({ (int) x, (int) y, 1, 1 });
            menu.popup ();
        }
    }
}