class graphite (
    $tz_region        = 'Etc',
    $tz_locality      = 'UTC',

    $whisper_data_dir = undef,
) {
    $timezone = "${tz_region}/${tz_locality}"
}
