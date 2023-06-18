using Ensembles.Models;

namespace Ensembles.ArrangerWorkstation.FileLoaders {
    public class StyleFileLoader : Object, IStyleFileLoader {
        public Style[] styles;

        private List<Style?> style_list;

        private unowned IAWCore i_aw_core;

        public StyleFileLoader (IAWCore i_aw_core) {
            this.i_aw_core = i_aw_core;
        }

        /**
         * Get an array of style objects which can be passed into
         * style engines to play them
         */
        public Style[] get_styles () {
            if (style_list == null) {
                style_list = new List<Style?> ();
                unowned List<string> style_paths = i_aw_core.get_style_search_paths ();

                string path = "";
                style_paths.foreach ((style_path) => {
                    try {
                        Dir dir = Dir.open (style_path, 0);
                        string? name = null;
                        while ((name = dir.read_name ()) != null) {
                            path = Path.build_filename (style_path, name);
                            if (path.has_suffix (".enstl") && path.contains ("@")) {
                                try {
                                    var analyser = new Analysers.StyleAnalyser (path);
                                    style_list.append (analyser.get_style ());
                                } catch (StyleError e) {
                                    Console.log (e, Console.LogLevel.WARNING);
                                } catch (Error e) {
                                    Console.log ("Style file not found or invalid!", Console.LogLevel.WARNING);
                                }
                            }
                        }
                    } catch (FileError e) {
                        Console.log ("Style path <%s> not found".printf (path), Console.LogLevel.WARNING);
                    }
                });
                style_list.sort (stylecmp);
            }

            uint len = style_list.length ();
            var styles = new Style[len];
            uint i = 0;

            foreach (var style in style_list) {
                styles[i++] = (owned)style;
            }

            return styles;
        }

        private CompareFunc<Style?> stylecmp = (a, b) => {
            return (a.genre).ascii_casecmp (b.genre);
        };
    }
}
