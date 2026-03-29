# Laravel Backend Scope

Laravel backendga ko'chirilgan surface:
- Health route
- Admin auth + workshops + bookings + reviews pages/actions
- Owner auth + bookings + pricing + schedule + telegram + reviews pages/actions
- Auth API: login/register/forgot-password/me/update/password/push-token/test
- Public API: workshops/list/byId/availability/calendar/price-quote/reviews
- Booking API: list/create/reschedule/cancel
- Background jobs: booking reminders, review reminders, telegram sync
- Notifications: Telegram + Firebase push
- Data storage currently JSON files under backend_laravel/data

Migration strategy:
1. Bootstrap Laravel app alongside current backend.
2. Keep JSON files as initial storage layer for parity and zero data loss.
3. Port REST API first so Flutter app can swap base URL safely.
4. Port admin/owner HTML panels next.
5. Replace launchd service to point at Laravel public/index.php via php artisan serve or php-fpm.
