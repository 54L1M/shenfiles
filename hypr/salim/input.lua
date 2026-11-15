-- See https://wiki.hypr.land/configuring/core/config-options/ (input)
-- Per-device overrides: hl.device({ name = "...", ... }), names from `hyprctl devices`.

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
    },
})
