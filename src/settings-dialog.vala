using Gtk;
using Adw;

namespace Reader {
    public class SettingsDialog : Adw.Window {
        private ConfigManager config_manager;
        private Button font_button;
        private SpinButton font_size_spin;
        private SpinButton line_spacing_spin;
        private SpinButton letter_spacing_spin;
        private Switch dark_theme_switch;
        private Switch css_theme_switch;
        private Button color_button;
        private SpinButton reading_width_spin;
        private string selected_font_family;
        private string selected_color;
        
        public SettingsDialog (Gtk.Window? parent, ConfigManager config) {
            Object (
                title: "首选项",
                default_width: 500,
                default_height: 612,
                modal: true,
                transient_for: parent
            );
            
            config_manager = config;
            
            setup_ui ();
            load_settings ();
            
            // 窗口关闭时自动保存设置～
            this.close_request.connect (() => {
                save_settings ();
                return false;
            });
        }
        
        private void setup_ui () {
            var main_box = new Box (Orientation.VERTICAL, 0);
            
            var header_bar = new Adw.HeaderBar ();
            header_bar.set_title_widget (new Label ("首选项"));
            
            main_box.append (header_bar);
            
            var scrolled = new ScrolledWindow ();
            scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            scrolled.set_vexpand (true);
            
            var content_box = new Box (Orientation.VERTICAL, 0);
            content_box.set_margin_top (12);
            content_box.set_margin_bottom (12);
            content_box.set_margin_start (12);
            content_box.set_margin_end (12);
            
            setup_font_settings (content_box);
            setup_theme_settings (content_box);
            
            scrolled.set_child (content_box);
            main_box.append (scrolled);
            
            set_content (main_box);
        }
        
        private void setup_font_settings (Box parent) {
            var font_group = new Adw.PreferencesGroup ();
            font_group.set_title ("字体设置");
            
            var font_row = new Adw.ActionRow ();
            font_row.set_title ("字体");
            font_row.set_subtitle ("选择阅读字体");
            
            selected_font_family = config_manager.font_family;
            
            font_button = new Button.with_label (selected_font_family);
            font_button.set_valign (Align.CENTER);
            font_button.clicked.connect (on_font_button_clicked);
            font_row.add_suffix (font_button);
            font_group.add (font_row);
            
            var font_size_row = new Adw.ActionRow ();
            font_size_row.set_title ("字体大小");
            font_size_row.set_subtitle ("调整字体大小");
            
            font_size_spin = new SpinButton.with_range (8, 72, 1);
            font_size_spin.set_valign (Align.CENTER);
            font_size_row.add_suffix (font_size_spin);
            font_group.add (font_size_row);
            
            var line_spacing_row = new Adw.ActionRow ();
            line_spacing_row.set_title ("行距");
            line_spacing_row.set_subtitle ("调整行间距");
            
            line_spacing_spin = new SpinButton.with_range (1.0, 3.0, 0.1);
            line_spacing_spin.set_digits (1);
            line_spacing_spin.set_valign (Align.CENTER);
            line_spacing_row.add_suffix (line_spacing_spin);
            font_group.add (line_spacing_row);
            
            var letter_spacing_row = new Adw.ActionRow ();
            letter_spacing_row.set_title ("字距");
            letter_spacing_row.set_subtitle ("调整字符间距");
            
            letter_spacing_spin = new SpinButton.with_range (-2.0, 5.0, 0.1);
            letter_spacing_spin.set_digits (1);
            letter_spacing_spin.set_valign (Align.CENTER);
            letter_spacing_row.add_suffix (letter_spacing_spin);
            font_group.add (letter_spacing_row);
            
            var reading_width_row = new Adw.ActionRow ();
            reading_width_row.set_title ("阅读宽度");
            reading_width_row.set_subtitle ("设置内容的宽度");
            
            reading_width_spin = new SpinButton.with_range (400, 1200, 50);
            reading_width_spin.set_valign (Align.CENTER);
            reading_width_row.add_suffix (reading_width_spin);
            font_group.add (reading_width_row);
            
            parent.append (font_group);
        }
        
        private void setup_theme_settings (Box parent) {
            var theme_group = new Adw.PreferencesGroup ();
            theme_group.set_title ("主题设置");
            
            var dark_theme_row = new Adw.ActionRow ();
            dark_theme_row.set_title ("深色主题");
            dark_theme_row.set_subtitle ("虽然还是亮色好看QwQ");
            
            dark_theme_switch = new Switch ();
            dark_theme_switch.set_valign (Align.CENTER);
            dark_theme_row.add_suffix (dark_theme_switch);
            dark_theme_row.set_activatable_widget (dark_theme_switch);
            theme_group.add (dark_theme_row);

            var css_theme_row = new Adw.ActionRow ();
            css_theme_row.set_title ("好看的配色～");
            css_theme_row.set_subtitle ("好看哒～");

            css_theme_switch = new Switch ();
            css_theme_switch.set_valign (Align.CENTER);
            css_theme_row.add_suffix (css_theme_switch);
            css_theme_row.set_activatable_widget (css_theme_switch);
            theme_group.add (css_theme_row);
            
            var color_row = new Adw.ActionRow ();
            color_row.set_title ("文字颜色");
            color_row.set_subtitle ("修改文字颜色～");
            
            selected_color = config_manager.text_color;
            
            color_button = new Button.with_label ("选择颜色");
            color_button.set_valign (Align.CENTER);
            color_button.clicked.connect (on_color_button_clicked);
            color_row.add_suffix (color_button);
            theme_group.add (color_row);
            
            parent.append (theme_group);
        }
        
        private void load_settings () {
            selected_font_family = config_manager.font_family;
            font_button.set_label (selected_font_family);
            
            font_size_spin.set_value (config_manager.font_size);
            line_spacing_spin.set_value (config_manager.line_spacing);
            letter_spacing_spin.set_value (config_manager.letter_spacing);
            dark_theme_switch.set_active (config_manager.dark_theme);
            css_theme_switch.set_active (config_manager.css_theme);
            reading_width_spin.set_value (config_manager.reading_width);
            
            selected_color = config_manager.text_color;
        }
        
        private void save_settings () {
            config_manager.font_family = selected_font_family;
            config_manager.font_size = (int) font_size_spin.get_value ();
            config_manager.line_spacing = line_spacing_spin.get_value ();
            config_manager.letter_spacing = letter_spacing_spin.get_value ();
            config_manager.dark_theme = dark_theme_switch.get_active ();
            config_manager.css_theme = css_theme_switch.get_active ();
            config_manager.text_color = selected_color;
            config_manager.reading_width = (int) reading_width_spin.get_value ();
            
            config_manager.save_settings ();
        }
        
        private void on_font_button_clicked () {
            var font_chooser = new FontChooserDialog ("选择字体", this);
            font_chooser.set_font (selected_font_family);
            
            font_chooser.response.connect ((response) => {
                if (response == ResponseType.OK) {
                    selected_font_family = font_chooser.get_font_family ().get_name ();
                    font_button.set_label (selected_font_family);
                }
                font_chooser.destroy ();
            });
            
            font_chooser.show ();
        }
        
        private void on_color_button_clicked () {
            var color_chooser = new ColorChooserDialog ("选择颜色", this);
            
            var rgba = Gdk.RGBA ();
            rgba.parse (selected_color);
            color_chooser.set_rgba (rgba);
            
            color_chooser.response.connect ((response) => {
                if (response == ResponseType.OK) {
                    selected_color = color_chooser.get_rgba ().to_string ();
                }
                color_chooser.destroy ();
            });
            
            color_chooser.show ();
        }
    }
}
