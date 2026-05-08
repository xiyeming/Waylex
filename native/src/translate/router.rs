/// Router module holds routing logic for translation requests
/// Main routing is implemented in translate/mod.rs RequestRouter
pub struct TranslateRouter;

impl Default for TranslateRouter {
    fn default() -> Self {
        Self::new()
    }
}

impl TranslateRouter {
    pub fn new() -> Self {
        Self
    }
}
