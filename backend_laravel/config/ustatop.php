<?php

return [
    'storage_driver' => env('USTATOP_STORAGE_DRIVER', 'sqlite'),
    'sqlite_file' => env('USTATOP_SQLITE_FILE', storage_path('app/ustatop/ustatop.sqlite')),
    'storage_db_connection' => env('USTATOP_STORAGE_DB_CONNECTION', env('DB_CONNECTION', 'sqlite')),
    'storage_db_table' => env('USTATOP_STORAGE_DB_TABLE', 'ustatop_json_documents'),
    'data_dir' => env('USTATOP_DATA_DIR', base_path('data')),
    'users_file' => env('USTATOP_USERS_FILE', base_path('data/users.json')),
    'workshops_file' => env('USTATOP_WORKSHOPS_FILE', base_path('data/workshops.json')),
    'bookings_file' => env('USTATOP_BOOKINGS_FILE', base_path('data/bookings.json')),
    'cashback_transactions_file' => env('USTATOP_CASHBACK_TRANSACTIONS_FILE', base_path('data/cashback_transactions.json')),
    'reviews_file' => env('USTATOP_REVIEWS_FILE', base_path('data/reviews.json')),
    'booking_messages_file' => env('USTATOP_BOOKING_MESSAGES_FILE', base_path('data/booking_messages.json')),
    'workshop_locations_file' => env('USTATOP_WORKSHOP_LOCATIONS_FILE', base_path('data/workshop_locations.json')),
    'auth_sessions_file' => env('USTATOP_AUTH_SESSIONS_FILE', storage_path('app/ustatop/auth_sessions.json')),
    'sms_verifications_file' => env('USTATOP_SMS_VERIFICATIONS_FILE', storage_path('app/ustatop/sms_verifications.json')),
    'telegram_sync_state_file' => env('USTATOP_TELEGRAM_SYNC_STATE_FILE', storage_path('app/ustatop/telegram_sync_state.json')),
    'workshop_images_dir' => env('USTATOP_WORKSHOP_IMAGES_DIR', storage_path('app/ustatop/workshop-images')),
    'customer_avatars_dir' => env('USTATOP_CUSTOMER_AVATARS_DIR', storage_path('app/ustatop/customer-avatars')),
    'admin_username' => env('ADMIN_USERNAME', 'admin'),
    'admin_password' => env('ADMIN_PASSWORD', 'admin123'),
];
