using Ensembles.ArrangerWorkstation.Models;

namespace Ensembles.ArrangerWorkstation.FileLoaders {
    public interface IStyleFileLoader : Object {
        /**
         * Get an array of style objects which can be passed into
         * style engines to play them
         */
        public abstract Style[] get_styles ();
    }
}
