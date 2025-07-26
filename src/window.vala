using Gtk;
using Adw;

namespace Reader {
    public class Window : Adw.ApplicationWindow {
        private Stack main_stack;
        private BookShelf book_shelf;
        private ReaderView reader_view;
        private BookManager book_manager;
        private ConfigManager config_manager;

        public Window (Application app) {
            Object (application: app);
            
            setup_ui ();
            setup_actions ();
            load_window_state ();
        }

        private void setup_ui () {
            set_title ("阅读");
            set_default_size (900, 700);
            
            config_manager = new ConfigManager ();
            book_manager = new BookManager ();
            
            main_stack = new Stack ();
            main_stack.set_transition_type (StackTransitionType.SLIDE_LEFT_RIGHT);
            
            book_shelf = new BookShelf (book_manager, config_manager);
            book_shelf.book_selected.connect (on_book_selected);
            
            reader_view = new ReaderView (book_manager, config_manager);
            reader_view.back_requested.connect (on_back_to_shelf);
            
            main_stack.add_named (book_shelf, "shelf");
            main_stack.add_named (reader_view, "reader");
            
            set_content (main_stack);
            
            main_stack.set_visible_child_name ("shelf");
        }

        private void setup_actions () {
            var add_book_action = new SimpleAction ("add-book", null);
            add_book_action.activate.connect (on_add_book);
            add_action (add_book_action);

            var settings_action = new SimpleAction ("settings", null);
            settings_action.activate.connect (on_settings);
            add_action (settings_action);
        }

        private void load_window_state () {
            var settings = new GLib.Settings ("io.github.myueqf.reader");
            
            var width = settings.get_int ("window-width");
            var height = settings.get_int ("window-height");
            var maximized = settings.get_boolean ("window-maximized");
            
            set_default_size (width, height);
            
            if (maximized) {
                maximize ();
            }
        }

        private void save_window_state () {
            var settings = new GLib.Settings ("io.github.myueqf.reader");
            
            int width, height;
            get_default_size (out width, out height);
            
            settings.set_int ("window-width", width);
            settings.set_int ("window-height", height);
            settings.set_boolean ("window-maximized", is_maximized ());
        }

        private void on_add_book () {
            var file_chooser = new FileChooserNative (
                "选择文件",
                this,
                FileChooserAction.OPEN,
                "打开",
                "取消"
            );
            
            var filter = new FileFilter ();
            filter.set_filter_name ("TXT 文件");
            filter.add_pattern ("*.txt");
            file_chooser.add_filter (filter);
            
            file_chooser.response.connect ((response) => {
                if (response == ResponseType.ACCEPT) {
                    var file = file_chooser.get_file ();
                    if (file != null) {
                        book_manager.add_book_from_file (file);
                        book_shelf.refresh ();
                    }
                }
            });
            
            file_chooser.show ();
        }

        private void on_settings () {
            var settings_dialog = new SettingsDialog (this, config_manager);
            settings_dialog.present ();
        }

        private void on_book_selected (Book book) {
            reader_view.set_book (book);
            main_stack.set_visible_child_name ("reader");
        }

        private void on_back_to_shelf () {
            main_stack.set_visible_child_name ("shelf");
            book_shelf.update_recent_book_button ();  // 更新最近阅读按钮～
        }

        public override bool close_request () {
            save_window_state ();
            return false;
        }
    }
}
