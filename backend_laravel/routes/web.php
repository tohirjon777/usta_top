<?php

use App\Http\Controllers\Web\AdminController;
use App\Http\Controllers\Web\CustomerMediaController;
use App\Http\Controllers\Web\CustomerWebsiteController;
use App\Http\Controllers\Web\OwnerController;
use App\Http\Controllers\Web\WorkshopMediaController;
use Illuminate\Support\Facades\Route;

Route::get('/', [CustomerWebsiteController::class, 'home']);
Route::get('/privacy-policy', [CustomerWebsiteController::class, 'privacyPolicyPage']);
Route::get('/privacy', [CustomerWebsiteController::class, 'privacyPolicyPage']);
Route::get('/account/delete', [CustomerWebsiteController::class, 'accountDeletionPage']);
Route::get('/delete-account', [CustomerWebsiteController::class, 'accountDeletionPage']);
Route::get('/workshop/{id}', [CustomerWebsiteController::class, 'workshop']);
Route::get('/customer/login', [CustomerWebsiteController::class, 'loginPage']);
Route::post('/customer/login', [CustomerWebsiteController::class, 'login']);
Route::post('/customer/register', [CustomerWebsiteController::class, 'register']);
Route::post('/customer/logout', [CustomerWebsiteController::class, 'logout']);
Route::get('/customer/account', [CustomerWebsiteController::class, 'accountPage']);
Route::post('/customer/account/delete', [CustomerWebsiteController::class, 'deleteAccount']);
Route::post('/customer/profile', [CustomerWebsiteController::class, 'updateProfile']);
Route::post('/customer/avatar', [CustomerWebsiteController::class, 'updateAvatar']);
Route::post('/customer/password', [CustomerWebsiteController::class, 'updatePassword']);
Route::post('/customer/cards', [CustomerWebsiteController::class, 'addCard']);
Route::post('/customer/cards/{cardId}/update', [CustomerWebsiteController::class, 'updateCard']);
Route::post('/customer/cards/{cardId}/delete', [CustomerWebsiteController::class, 'deleteCard']);
Route::post('/customer/workshops/{id}/book', [CustomerWebsiteController::class, 'createBooking']);
Route::post('/customer/workshops/{id}/reviews', [CustomerWebsiteController::class, 'createReview']);
Route::post('/customer/bookings/{id}/cancel', [CustomerWebsiteController::class, 'cancelBooking']);
Route::post('/customer/bookings/{id}/reschedule', [CustomerWebsiteController::class, 'rescheduleBooking']);
Route::post('/customer/bookings/{id}/accept-reschedule', [CustomerWebsiteController::class, 'acceptRescheduled']);
Route::post('/customer/bookings/{id}/messages', [CustomerWebsiteController::class, 'sendMessage']);
Route::get('/media/workshops/{filename}', [WorkshopMediaController::class, 'showWorkshopImage'])
    ->where('filename', '[A-Za-z0-9._-]+');
Route::get('/media/customers/{filename}', [CustomerMediaController::class, 'showCustomerAvatar'])
    ->where('filename', '[A-Za-z0-9._-]+');

Route::prefix('admin')->controller(AdminController::class)->group(function (): void {
    Route::get('/', 'entry');
    Route::get('/login', 'loginPage');
    Route::post('/login', 'login');
    Route::post('/logout', 'logout');

    Route::get('/workshops', 'workshopsPage');
    Route::post('/workshops', 'createWorkshop');
    Route::post('/workshops/{id}/update', 'updateWorkshop');
    Route::post('/workshops/{id}/delete', 'deleteWorkshop');
    Route::post('/workshops/{id}/telegram/test', 'sendTelegramTest');
    Route::post('/workshops/{id}/location', 'updateWorkshopLocation');
    Route::get('/workshops/{id}/vehicle-pricing/template.xlsx', 'downloadVehiclePricingTemplate');
    Route::post('/workshops/{id}/vehicle-pricing/import', 'importVehiclePricing');

    Route::get('/bookings', 'bookingsPage');
    Route::post('/bookings/{id}/status', 'updateBookingStatus');

    Route::get('/analytics', 'analyticsPage');
    Route::get('/analytics/export.csv', 'exportAnalyticsCsv');

    Route::get('/reviews', 'reviewsPage');
    Route::post('/reviews/{id}/hide', 'hideReview');
    Route::post('/reviews/{id}/unhide', 'unhideReview');
    Route::post('/reviews/{id}/remind', 'remindReview');
});

Route::prefix('owner')->controller(OwnerController::class)->group(function (): void {
    Route::get('/', 'entry');
    Route::get('/login', 'loginPage');
    Route::post('/login', 'login');
    Route::post('/logout', 'logout');

    Route::get('/bookings', 'bookingsPage');
    Route::post('/bookings/{id}/status', 'updateStatus');
    Route::post('/services', 'createService');
    Route::post('/services/{id}/price', 'updateService');
    Route::post('/reviews/{id}/reply', 'replyReview');

    Route::post('/telegram/generate', 'generateTelegramLinkCode');
    Route::post('/telegram/check', 'checkTelegramLink');
    Route::post('/telegram/disconnect', 'disconnectTelegram');

    Route::get('/vehicle-pricing/template.xlsx', 'downloadVehiclePricingTemplate');
    Route::post('/vehicle-pricing/import', 'importVehiclePricing');
    Route::post('/schedule', 'updateSchedule');
    Route::post('/workshop/image', 'updateWorkshopImage');
    Route::post('/workshop/location', 'updateWorkshopLocation');
});
