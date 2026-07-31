use crate::executable::SpecialExecutable;

macro_rules! opt {
    ($rulename:ident) => { opt!($rulename, []); };
    ($rulename:ident, [$($variant:ident),*]) => {
        pub fn $rulename(exec: Option<SpecialExecutable>) -> bool {
            match exec {
                Some(o) => match o {
                    $(SpecialExecutable::$variant => true,)*
                    _ => false,
                },
                _ => false,
            }
        }
    };
}

opt!(gpu);
opt!(gui);
opt!(dbus);
opt!(internet);
opt!(no_project);
opt!(setsid, [Helix]);
opt!(editor, [Helix]);
