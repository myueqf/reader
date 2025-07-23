
namespace Reader {
    public class ConfigManager : GLib.Object {
        private GLib.Settings settings;
        
        public string font_family { get; set; }
        public int font_size { get; set; }
        public double line_spacing { get; set; }
        public double letter_spacing { get; set; }
        public bool dark_theme { get; set; }
        public string text_color { get; set; }
        public int reading_width { get; set; }
        
        public signal void config_changed ();
        
        public ConfigManager () {
            font_family = "Source Han Sans CN";
            font_size = 28;
            line_spacing = 2.2;
            letter_spacing = 0.0;
            dark_theme = false;
            text_color = "#3d3846";
            reading_width = 750;
            
            try {
                settings = new GLib.Settings ("io.github.myueqf.reader");
                load_settings ();
            } catch (Error e) {
                warning ("无法加载设置XwX: %s", e.message);
            }
        }
        
        private void load_settings () {
            if (settings == null) return;
            
            try {
                font_family = settings.get_string ("font-family");
                font_size = settings.get_int ("font-size");
                line_spacing = settings.get_double ("line-spacing");
                letter_spacing = settings.get_double ("letter-spacing");
                dark_theme = settings.get_boolean ("dark-theme");
                text_color = settings.get_string ("text-color");
                reading_width = settings.get_int ("reading-width");
            } catch (Error e) {
                warning ("加载设置时出错XwX: %s", e.message);
            }
        }
        
        public void save_settings () {
            if (settings == null) return;
            
            try {
                settings.set_string ("font-family", font_family);
                settings.set_int ("font-size", font_size);
                settings.set_double ("line-spacing", line_spacing);
                settings.set_double ("letter-spacing", letter_spacing);
                settings.set_boolean ("dark-theme", dark_theme);
                settings.set_string ("text-color", text_color);
                settings.set_int ("reading-width", reading_width);
                
                config_changed ();
            } catch (Error e) {
                warning ("保存设置时出错XwX: %s", e.message);
            }
        }
        
        public void apply_theme () {
            try {
                var style_manager = Adw.StyleManager.get_default ();
                if (dark_theme) {
                    style_manager.set_color_scheme (Adw.ColorScheme.FORCE_DARK);
                } else {
                    style_manager.set_color_scheme (Adw.ColorScheme.FORCE_LIGHT);
                }
            } catch (Error e) {
                warning ("应用主题出错XwX: %s", e.message);
            }
        }
        
        public string get_font_css () {
            return "font-family: \"%s\"; font-size: %dpx; line-height: %.2f; letter-spacing: %.2fpx; color: %s;".printf (
                font_family, font_size, line_spacing, letter_spacing, text_color
            );
        }
    }
}