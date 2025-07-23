desktop_file = configure_file(
  input: 'io.github.myueqf.reader.desktop.in',
  output: 'io.github.myueqf.reader.desktop',
  configuration: conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

appdata_file = configure_file(
  input: 'io.github.myueqf.reader.appdata.xml.in',
  output: 'io.github.myueqf.reader.appdata.xml',
  configuration: conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data('io.github.myueqf.reader.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data('io.github.myueqf.reader.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

gnome.compile_schemas()