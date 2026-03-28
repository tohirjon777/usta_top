<?php

return [
    'data_dir' => env('USTATOP_DATA_DIR', base_path('data')),
    'users_file' => env('USTATOP_USERS_FILE', base_path('data/users.json')),
    'workshops_file' => env('USTATOP_WORKSHOPS_FILE', base_path('data/workshops.json')),
    'bookings_file' => env('USTATOP_BOOKINGS_FILE', base_path('data/bookings.json')),
    'reviews_file' => env('USTATOP_REVIEWS_FILE', base_path('data/reviews.json')),
    'booking_messages_file' => env('USTATOP_BOOKING_MESSAGES_FILE', base_path('data/booking_messages.json')),
    'workshop_locations_file' => env('USTATOP_WORKSHOP_LOCATIONS_FILE', base_path('data/workshop_locations.json')),
    'auth_sessions_file' => env('USTATOP_AUTH_SESSIONS_FILE', storage_path('app/ustatop/auth_sessions.json')),
    'admin_username' => env('ADMIN_USERNAME', 'admin'),
    'admin_password' => env('ADMIN_PASSWORD', 'admin123'),
];
