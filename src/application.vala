using Gtk;
using Adw;

namespace Reader {
    public class Application : Adw.Application {
        public Application () {
            Object (
                application_id: "io.github.myueqf.reader",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            var window = new Reader.Window (this);
            window.present ();
        }

        protected override void startup () {
            base.startup ();
            
            Adw.init ();

            var config_manager = new ConfigManager ();
            config_manager.apply_theme ();
            
            var provider = new CssProvider ();
            provider.load_from_resource ("/io/github/myueqf/reader/style.css");
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
    }
}