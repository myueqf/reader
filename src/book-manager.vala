using Json;
using Gee;

namespace Reader {
    public class BookManager : GLib.Object {
        private ArrayList<Book> books;
        private string books_dir;
        
        public signal void book_added (Book book);
        public signal void book_removed (Book book);
        public signal void book_updated (Book book);
        
        public BookManager () {
            books = new ArrayList<Book> ();
            books_dir = GLib.Path.build_filename (Environment.get_user_config_dir (), "reader", "book");
            
            ensure_books_directory ();
            load_books ();
        }
        
        private void ensure_books_directory () {
            var dir = File.new_for_path (books_dir);
            try {
                if (!dir.query_exists ()) {
                    dir.make_directory_with_parents ();
                }
            } catch (Error e) {
                warning ("创建书籍目录失败XwX: %s", e.message);
            }
        }
        
        public void load_books () {
            books.clear ();
            
            var dir = File.new_for_path (books_dir);
            try {
                var enumerator = dir.enumerate_children (
                    FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );
                
                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    if (file_info.get_file_type () == FileType.DIRECTORY) {
                        var book_dir = file_info.get_name ();
                        var config_file = GLib.Path.build_filename (books_dir, book_dir, "config.json");
                        
                        if (File.new_for_path (config_file).query_exists ()) {
                            load_book_from_config (config_file, GLib.Path.build_filename (books_dir, book_dir));
                        }
                    }
                }
            } catch (Error e) {
                warning ("加载书籍失败XwX: %s", e.message);
            }
        }
        
        private void load_book_from_config (string config_path, string book_dir) {
            try {
                var parser = new Json.Parser ();
                parser.load_from_file (config_path);
                
                var root = parser.get_root ();
                var book = new Book.from_json (root, book_dir);
                books.add (book);
            } catch (Error e) {
                warning ("加载书籍配置失败XwX %s: %s", config_path, e.message);
            }
        }
        
        public void add_book_from_file (File file) {
            try {
                var basename = file.get_basename ();

                // 限制过大的文件QWQ
                var file_info = file.query_info (FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
                var file_size = file_info.get_size ();
                if (file_size > 15 * 1024 * 1024) {
                    return;
                }
                
                var book = new Book ();
                book.name = get_filename_without_extension (basename);
                book.author = "未知作者";
                book.files = basename;
                
                var safe_name = sanitize_filename (book.name);
                var book_dir = GLib.Path.build_filename (books_dir, safe_name);
                
                // 检查相同的书（木啥用XwX）
                /*
                var existing_book = find_book_by_name (book.name)
                if (existing_book != null) {
                    warning ("已存在: %s", book.name);
                    return;
                }
                */

                var dir = File.new_for_path (book_dir);
                if (!dir.query_exists ()) {
                    dir.make_directory_with_parents ();
                }
                
                var dest_file = File.new_for_path (GLib.Path.build_filename (book_dir, basename));
                file.copy (dest_file, FileCopyFlags.OVERWRITE);
                
                book.directory = book_dir;
                book.load_content ();
                book.parse_chapters ();
                
                save_book_config (book);
                books.add (book);
                
                book_added (book);
                
                var edit_dialog = new BookEditDialog (null, book);
                edit_dialog.book_updated.connect ((updated_book) => {
                    save_book_config (updated_book);
                    book_updated (updated_book);
                });
                edit_dialog.present ();
                
            } catch (Error e) {
                warning ("添加失败XwX: %s", e.message);
            }
        }
        
        private string get_filename_without_extension (string filename) {
            var dot_index = filename.last_index_of (".");
            return dot_index > 0 ? filename.substring (0, dot_index) : filename;
        }
        
        private string sanitize_filename (string filename) {
            return filename.replace ("/", "_")
                           .replace ("\\", "_")
                           .replace (":", "_")
                           .replace ("*", "_")
                           .replace ("?", "_")
                           .replace ("\"", "_")
                           .replace ("<", "_")
                           .replace (">", "_")
                           .replace ("|", "_");
        }
        
        public void save_book_config (Book book) {
            var config_path = GLib.Path.build_filename (book.directory, "config.json");

            try {
                var generator = new Json.Generator ();
                generator.set_root (book.to_json ());
                generator.pretty = true;
                generator.to_file (config_path);
            } catch (Error e) {
                warning ("保存书籍配置失败: %s", e.message);
            }
        }
        
        public void remove_book (Book book) {
            books.remove (book);
            
            try {
                var dir = File.new_for_path (book.directory);
                delete_directory_recursive (dir);
                book_removed (book);
            } catch (Error e) {
                warning ("删除书籍失败: %s", e.message);
            }
        }
        
        private void delete_directory_recursive (File dir) throws Error {
            var enumerator = dir.enumerate_children (
                FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NONE
            );
            
            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                var child = dir.get_child (file_info.get_name ());
                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    delete_directory_recursive (child);
                } else {
                    child.delete ();
                }
            }
            
            dir.delete ();
        }
        
        public ArrayList<Book> get_books () {
            return books;
        }
        
        public Book? find_book_by_name (string name) {
            foreach (var book in books) {
                if (book.name == name) {
                    return book;
                }
            }
            return null;
        }
        
        public Book? get_book (int index) {
            if (index < 0 || index >= books.size) {
                return null;
            }
            return books[index];
        }

        public Book? get_book_by_uuid (string uuid) {
            foreach (var book in books) {
                if (book.uuid == uuid) {
                    return book;
                }
            }
            return null;
        }
    }
}