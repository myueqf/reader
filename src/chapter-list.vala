using Gtk;
using Adw;

namespace Reader {
    public class ChapterListDialog : Adw.Window {
        private Book book;
        private ListView chapter_list;
        private StringList chapter_model;
        private int current_chapter_index;
        
        public signal void chapter_selected (int index);
        
        public ChapterListDialog (Gtk.Window? parent, Book book, int current_chapter = -1) {
            Object (
                title: "目录",
                default_width: 400,
                default_height: 600,
                modal: true,
                transient_for: parent
            );
            
            this.book = book;
            this.current_chapter_index = current_chapter;
            
            setup_ui ();
            load_chapters ();
        }
        
        private void setup_ui () {
            var main_box = new Box (Orientation.VERTICAL, 0);
            
            var header_bar = new Adw.HeaderBar ();
            header_bar.set_title_widget (new Label ("目录"));
            
            main_box.append (header_bar);
            
            var scrolled = new ScrolledWindow ();
            scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            scrolled.set_vexpand (true);
            
            chapter_model = new StringList (null);
            
            var factory = new SignalListItemFactory ();
            factory.setup.connect (on_factory_setup);
            factory.bind.connect (on_factory_bind);
            
            var selection = new SingleSelection (chapter_model);
            chapter_list = new ListView (selection, factory);
            chapter_list.set_single_click_activate (true);
            chapter_list.activate.connect (on_chapter_activated);
            
            scrolled.set_child (chapter_list);
            main_box.append (scrolled);
            
            set_content (main_box);
        }
        
        private void on_factory_setup (Object item) {
            var list_item = item as ListItem;
            if (list_item == null) return;
            
            var box = new Box (Orientation.HORIZONTAL, 8);
            box.set_margin_top (8);
            box.set_margin_bottom (8);
            box.set_margin_start (12);
            box.set_margin_end (12);
            
            var label = new Label ("");
            label.set_xalign (0);
            label.set_wrap (true);
            label.set_ellipsize (Pango.EllipsizeMode.END);
            label.set_hexpand (true);
            
            var current_marker = new Label ("");
            current_marker.set_xalign (1);
            current_marker.add_css_class ("current-chapter-marker");
            
            box.append (label);
            box.append (current_marker);
            list_item.set_child (box);
        }
        
        private void on_factory_bind (Object item) {
            var list_item = item as ListItem;
            if (list_item == null) return;
            
            var string_object = list_item.get_item () as StringObject;
            if (string_object == null) return;
            
            var box = list_item.get_child () as Box;
            if (box == null) return;
            
            var label = box.get_first_child () as Label;
            var current_marker = box.get_last_child () as Label;
            if (label == null || current_marker == null) return;
            
            var chapter_index = (int) list_item.get_position ();
            
            label.set_text (string_object.get_string ());
            
            // 标记下正在阅读的章节QWQ
            if (chapter_index == current_chapter_index) {
                current_marker.set_text ("##");
                current_marker.set_visible (true);
            } else {
                current_marker.set_visible (false);
            }
        }
        
        private void load_chapters () {
            var chapters = book.get_chapters ();
            
            chapter_model.splice (0, chapter_model.get_n_items (), null);
            
            foreach (var chapter in chapters) {
                var chapter_text = @"$(chapter.index). $(chapter.title)";
                chapter_model.append (chapter_text);
            }
        }
        
        private void on_chapter_activated (uint position) {
            chapter_selected ((int) position);
            destroy ();
        }
    }
    
    public class ChapterList : Box {
        private Book book;
        private ListView chapter_list;
        private StringList chapter_model;
        private int current_chapter_index;
        
        public signal void chapter_selected (int index);
        
        public ChapterList (Book book, int current_chapter = -1) {
            this.book = book;
            this.current_chapter_index = current_chapter;
            
            set_orientation (Orientation.VERTICAL);
            set_spacing (0);
            
            setup_ui ();
            load_chapters ();
        }
        
        private void setup_ui () {
            var header = new Label ("章节目录");
            header.add_css_class ("heading");
            header.set_margin_top (12);
            header.set_margin_bottom (12);
            append (header);
            
            var scrolled = new ScrolledWindow ();
            scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            scrolled.set_vexpand (true);
            
            chapter_model = new StringList (null);
            
            var factory = new SignalListItemFactory ();
            factory.setup.connect (on_factory_setup);
            factory.bind.connect (on_factory_bind);
            
            var selection = new SingleSelection (chapter_model);
            chapter_list = new ListView (selection, factory);
            chapter_list.set_single_click_activate (true);
            chapter_list.activate.connect (on_chapter_activated);
            
            scrolled.set_child (chapter_list);
            append (scrolled);
        }
        
        private void on_factory_setup (Object item) {
            var list_item = item as ListItem;
            if (list_item == null) return;
            
            var box = new Box (Orientation.HORIZONTAL, 8);
            box.set_margin_top (8);
            box.set_margin_bottom (8);
            box.set_margin_start (12);
            box.set_margin_end (12);
            
            var label = new Label ("");
            label.set_xalign (0);
            label.set_wrap (true);
            label.set_ellipsize (Pango.EllipsizeMode.END);
            label.set_hexpand (true);
            
            var current_marker = new Label ("");
            current_marker.set_xalign (1);
            current_marker.add_css_class ("current-chapter-marker");
            
            box.append (label);
            box.append (current_marker);
            list_item.set_child (box);
        }
        
        private void on_factory_bind (Object item) {
            var list_item = item as ListItem;
            if (list_item == null) return;
            
            var string_object = list_item.get_item () as StringObject;
            if (string_object == null) return;
            
            var box = list_item.get_child () as Box;
            if (box == null) return;
            
            var label = box.get_first_child () as Label;
            var current_marker = box.get_last_child () as Label;
            if (label == null || current_marker == null) return;
            
            var chapter_index = (int) list_item.get_position ();
            
            label.set_text (string_object.get_string ());
            
            // 标记下正在阅读的章节XwX
            if (chapter_index == current_chapter_index) {
                current_marker.set_text ("##");
                current_marker.set_visible (true);
            } else {
                current_marker.set_visible (false);
            }
        }
        
        private void load_chapters () {
            var chapters = book.get_chapters ();
            
            chapter_model.splice (0, chapter_model.get_n_items (), null);
            
            foreach (var chapter in chapters) {
                var chapter_text = @"$(chapter.index). $(chapter.title)";
                chapter_model.append (chapter_text);
            }
        }
        
        private void on_chapter_activated (uint position) {
            chapter_selected ((int) position);
        }
        
        public void refresh (int current_chapter = -1) {
            this.current_chapter_index = current_chapter;
            load_chapters ();
        }
    }
}