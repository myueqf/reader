project('reader', 'vala', 'c',
  version: '1.0.0',
  meson_version: '>= 0.56.0',
  default_options: ['warning_level=2', 'werror=false']
)

gnome = import('gnome')

vala_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('json-glib-1.0'),
  dependency('gee-0.8'),
  dependency('gio-2.0'),
  dependency('glib-2.0'),
]

conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', 'reader')
conf.set_quoted('GNOMELOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf.set_quoted('PACKAGE_NAME', 'reader')
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('APPLICATION_ID', 'io.github.myueqf.reader')

config_h = configure_file(
  output: 'config.h',
  configuration: conf
)

resources = gnome.compile_resources(
  'reader-resources',
  'resources/resources.gresource.xml',
  source_dir: 'resources',
  c_name: 'reader'
)

src_files = [
  'src/main.vala',
  'src/application.vala',
  'src/window.vala',
  'src/book.vala',
  'src/book-manager.vala',
  'src/book-shelf.vala',
  'src/book-item.vala',
  'src/book-edit-dialog.vala',
  'src/reader-view.vala',
  'src/chapter-list.vala',
  'src/settings-dialog.vala',
  'src/config-manager.vala',
]

executable('reader',
  src_files,
  resources,
  dependencies: vala_deps,
  install: true,
  install_dir: get_option('bindir')
)

subdir('data')

