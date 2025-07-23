using Gtk;
using Adw;

namespace Reader {
    public class BookShelf : Box {
        private BookManager book_manager;
        private FlowBox book_flow;
        private Gtk.HeaderBar header_bar;

        public signal void book_selected (Book book);

        public BookShelf (BookManager manager) {
            book_manager = manager;

            setup_ui ();
            setup_connections ();
            refresh ();
        }

        private void setup_ui () {
            set_orientation (Orientation.VERTICAL);
            set_spacing (0);

            header_bar = new Gtk.HeaderBar ();
            header_bar.set_title_widget (new Label ("书架"));

            var add_button = new Button.with_label ("添加");
            add_button.add_css_class ("suggested-action");
            add_button.clicked.connect (() => {
                var window = get_root () as Window;
                if (window != null) {
                    window.activate_action ("add-book", null);
                }
            });
            header_bar.pack_end (add_button);

            var settings_button = new Button.from_icon_name ("preferences-system-symbolic");
            settings_button.tooltip_text = "首选项";
            settings_button.clicked.connect (() => {
                var window = get_root () as Window;
                if (window != null) {
                    window.activate_action ("settings", null);
                }
            });
            header_bar.pack_end (settings_button);

            append (header_bar);
            /**
            一些示例QWQ（懒～）

            分隔符：
            var sep = new Gtk.Separator (Orientation.HORIZONTAL);
            sidebar.append (sep);

            占位：
            var placeholder = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder.vexpand = true;
            sidebar.append (placeholder);

            文本
            var label2 = new Gtk.Label ("  天官赐福，百无禁忌。");
            label2.set_name ("reading-label");
            sidebar.append (label2);

            */
            /* 侧边栏 */
            var hbox = new Gtk.Box (Orientation.HORIZONTAL, 0);
            hbox.set_vexpand (true);
            append (hbox);

            var sidebar = new Gtk.Box (Orientation.VERTICAL, 6);
            sidebar.set_margin_top (12);
            sidebar.set_margin_bottom (12);
            sidebar.set_margin_start (12);
            sidebar.set_margin_end (12);
            sidebar.set_size_request (210, -1);

            // 标题～
            var title = new Gtk.Label ("阅读");
            title.set_name ("title-label");
            title.set_xalign ((float) 0.00);
            sidebar.append (title);
            var label1 = new Gtk.Label ("副标题～");
            label1.set_label ("杳杳花见时，一眼怅然失"); /** 来源：花亦山 */
            label1.set_name ("label1-label");
            label1.set_xalign ((float) 1.00);
            sidebar.append (label1);
            // 分隔符
            var sep = new Gtk.Separator (Orientation.HORIZONTAL);
            sidebar.append (sep);
            // 占位（24px）
            var placeholder5 = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder5.height_request = 24;
            sidebar.append (placeholder5);
            // 最近阅读
            var label2 = new Gtk.Label ("最近阅读");
            label2.get_style_context().add_class ("text-color");
            label2.set_xalign ((float) 0.08);
            sidebar.append (label2);
            var btn1 = new Button.with_label ("木做QAQ");
            btn1.get_style_context().add_class ("text-color");
            sidebar.append (btn1); // 按钮1
            // 占位（24px）
            var placeholder1 = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder1.height_request = 24;
            sidebar.append (placeholder1);
            // 基本设定
            var label3 = new Gtk.Label ("基本设定");
            label3.get_style_context().add_class ("text-color");
            label3.set_xalign ((float) 0.08);
            sidebar.append (label3);
            var btn2 = new Button.with_label ("木做QAQ");
            btn2.get_style_context().add_class ("text-color");
            sidebar.append (btn2); // 按钮2
            var btn3 = new Button.with_label ("小说数量统计QWQ"); // 感觉加了这个怪无聊的XwX
            var books = book_manager.get_books();
            btn3.set_label ("有" + books.size.to_string() + "本小说嗷～");
            btn3.get_style_context().add_class ("text-color");
            sidebar.append (btn3);
            // 占位
            var placeholder2 = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder2.vexpand = true;
            sidebar.append (placeholder2);
            // 占位
            var placeholder3 = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder3.vexpand = true;
            sidebar.append (placeholder3);
            // 占位
            var placeholder4 = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder4.vexpand = true;
            sidebar.append (placeholder4);
            // 占位
            var placeholder = new Gtk.Box (Orientation.VERTICAL, 0);
            placeholder.vexpand = true;
            sidebar.append (placeholder);
            /* github图标～ */
            var btn = new Gtk.Button ();
            btn.halign = Gtk.Align.START;
            btn.get_style_context().add_class ("flat-button");
            var img = new Gtk.Image.from_resource ("/io/github/myueqf/reader/icon_github.svg");
            img.pixel_size = 37;
            btn.set_child (img);
            btn.clicked.connect (() =>
                Gtk.show_uri (null, "https://github.com/myueqf/", Gdk.CURRENT_TIME)
            );
            sidebar.append (btn);



            hbox.append (sidebar);
            /* 书籍列表 */
            var scrolled = new ScrolledWindow ();
            scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            scrolled.set_vexpand (true);
            scrolled.set_hexpand (true);

            book_flow = new FlowBox ();
            book_flow.set_valign (Align.START);
            book_flow.set_max_children_per_line (4);
            book_flow.set_selection_mode (SelectionMode.NONE);
            book_flow.set_homogeneous (true);
            book_flow.set_column_spacing (12);
            book_flow.set_row_spacing (12);
            book_flow.set_margin_top (12);
            book_flow.set_margin_bottom (12);
            book_flow.set_margin_start (12);
            book_flow.set_margin_end (12);

            scrolled.set_child (book_flow);

            /* 分～隔～符～ */
            var separator = new Gtk.Separator (Orientation.VERTICAL);
            separator.set_margin_start (6);
            separator.set_margin_end   (6);
            hbox.append (separator);
            hbox.append (scrolled);

            if (book_manager.get_books ().size == 0) {
                show_empty_state ();
            }
        }

        private void setup_connections () {
            book_manager.book_added.connect ((book) => {
                refresh ();
            });

            book_manager.book_removed.connect ((book) => {
                refresh ();
            });

            book_manager.book_updated.connect ((book) => {
                refresh ();
            });
        }

        private void show_empty_state () {
            var empty_page = new Adw.StatusPage ();
            empty_page.set_title ("还没有小说");
            empty_page.set_description ("点击上方的\"添加\"来导入文件");
            empty_page.set_icon_name ("folder-documents-symbolic");

            book_flow.remove_all ();

            var child = new FlowBoxChild ();
            child.set_child (empty_page);
            child.set_sensitive (false);
            book_flow.append (child);
        }

        public void refresh () {
            book_flow.remove_all ();

            var books = book_manager.get_books ();
            if (books.size == 0) {
                show_empty_state ();
                return;
            }

            foreach (var book in books) {
                var book_item = new BookItem (book);
                book_item.book_selected.connect ((selected_book) => {
                    book_selected (selected_book);
                });
                book_item.book_edit_requested.connect ((book_to_edit) => {
                    var edit_dialog = new BookEditDialog (get_root () as Gtk.Window, book_to_edit);
                    edit_dialog.book_updated.connect ((updated_book) => {
                        book_manager.save_book_config (updated_book);
                        refresh ();
                    });
                    edit_dialog.present ();
                });
                book_item.book_delete_requested.connect ((book_to_delete) => {
                    show_delete_confirmation (book_to_delete);
                });

                book_flow.append (book_item);
            }
        }

        private void show_delete_confirmation (Book book) {
            var dialog = new Adw.AlertDialog (
                "你确定要删除《%s》吗？".printf (book.name),
                "“%s”将会永久消失！（真的很久！）".printf (book.name)
                // "这个操作不可撤销，将会删除所有相关文件。"
            );

            dialog.add_response ("cancel", "取消");
            dialog.add_response ("delete", "删除");
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.set_default_response ("cancel");
            dialog.set_close_response ("cancel");

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    book_manager.remove_book (book);
                }
            });

            dialog.present (get_root () as Gtk.Window);
        }
    }
}
