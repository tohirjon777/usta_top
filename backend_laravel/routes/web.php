<?php

use App\Http\Controllers\Web\AdminController;
use App\Http\Controllers\Web\CustomerWebsiteController;
use App\Http\Controllers\Web\OwnerController;
use App\Http\Controllers\Web\WorkshopMediaController;
use Illuminate\Support\Facades\Route;

Route::get('/', [CustomerWebsiteController::class, 'home']);
Route::get('/workshop/{id}', [CustomerWebsiteController::class, 'workshop']);
Route::get('/customer/login', [CustomerWebsiteController::class, 'loginPage']);
Route::post('/customer/login', [CustomerWebsiteController::class, 'login']);
Route::post('/customer/register', [CustomerWebsiteController::class, 'register']);
Route::post('/customer/logout', [CustomerWebsiteController::class, 'logout']);
Route::get('/customer/account', [CustomerWebsiteController::class, 'accountPage']);
Route::post('/customer/profile', [CustomerWebsiteController::class, 'updateProfile']);
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

Route::get('/admin', [AdminController::class, 'entry']);
Route::get('/admin/login', [AdminController::class, 'loginPage']);
Route::post('/admin/login', [AdminController::class, 'login']);
Route::post('/admin/logout', [AdminController::class, 'logout']);
Route::get('/admin/workshops', [AdminController::class, 'workshopsPage']);
Route::post('/admin/workshops', [AdminController::class, 'createWorkshop']);
Route::post('/admin/workshops/{id}/update', [AdminController::class, 'updateWorkshop']);
Route::post('/admin/workshops/{id}/delete', [AdminController::class, 'deleteWorkshop']);
Route::get('/admin/workshops/{id}/vehicle-pricing/template.xlsx', [AdminController::class, 'downloadVehiclePricingTemplate']);
Route::post('/admin/workshops/{id}/vehicle-pricing/import', [AdminController::class, 'importVehiclePricing']);
Route::post('/admin/workshops/{id}/telegram/test', [AdminController::class, 'sendTelegramTest']);
Route::get('/admin/bookings', [AdminController::class, 'bookingsPage']);
Route::get('/admin/analytics', [AdminController::class, 'analyticsPage']);
Route::get('/admin/analytics/export.csv', [AdminController::class, 'exportAnalyticsCsv']);
Route::post('/admin/bookings/{id}/status', [AdminController::class, 'updateBookingStatus']);
Route::get('/admin/reviews', [AdminController::class, 'reviewsPage']);
Route::post('/admin/reviews/{id}/hide', [AdminController::class, 'hideReview']);
Route::post('/admin/reviews/{id}/unhide', [AdminController::class, 'unhideReview']);
Route::post('/admin/reviews/{id}/remind', [AdminController::class, 'remindReview']);
Route::post('/admin/workshops/{id}/location', [AdminController::class, 'updateWorkshopLocation']);

Route::get('/owner', [OwnerController::class, 'entry']);
Route::get('/owner/login', [OwnerController::class, 'loginPage']);
Route::post('/owner/login', [OwnerController::class, 'login']);
Route::post('/owner/logout', [OwnerController::class, 'logout']);
Route::get('/owner/bookings', [OwnerController::class, 'bookingsPage']);
Route::post('/owner/bookings/{id}/status', [OwnerController::class, 'updateStatus']);
Route::post('/owner/services/{id}/price', [OwnerController::class, 'updateService']);
Route::get('/owner/vehicle-pricing/template.xlsx', [OwnerController::class, 'downloadVehiclePricingTemplate']);
Route::post('/owner/vehicle-pricing/import', [OwnerController::class, 'importVehiclePricing']);
Route::post('/owner/schedule', [OwnerController::class, 'updateSchedule']);
Route::post('/owner/workshop/image', [OwnerController::class, 'updateWorkshopImage']);
Route::post('/owner/reviews/{id}/reply', [OwnerController::class, 'replyReview']);
Route::post('/owner/telegram/generate', [OwnerController::class, 'generateTelegramLinkCode']);
Route::post('/owner/telegram/check', [OwnerController::class, 'checkTelegramLink']);
Route::post('/owner/telegram/disconnect', [OwnerController::class, 'disconnectTelegram']);
