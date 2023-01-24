function debug.on {
    $Global:DebugPreference = "Continue"
}

function debug.off {
    $Global:DebugPreference = "SilentlyContinue"
}

function logging.level.high {
    $Settings.logging.level = 2
}

function logging.level.medium {
    $Settings.logging.level = 1
}

function logging.level.low {
    $Settings.logging.level = 0
}

function verbose.on {
    $Global:VerbosePreference = "Continue"
}

function verbose.off {
    $Global:VerbosePreference = "SilentlyContinue"
}