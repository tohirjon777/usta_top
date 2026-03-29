<?php

use App\Http\Controllers\Web\AdminController;
use App\Http\Controllers\Web\OwnerController;
use App\Http\Controllers\Web\WorkshopMediaController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect('/admin/login'));
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
Route::post('/admin/workshops/{id}/telegram/test', [AdminController::class, 'sendTelegramTest']);
Route::get('/admin/bookings', [AdminController::class, 'bookingsPage']);
Route::get('/admin/analytics', [AdminController::class, 'analyticsPage']);
Route::get('/admin/analytics/export.csv', [AdminController::class, 'exportAnalyticsCsv']);
Route::post('/admin/bookings/{id}/status', [AdminController::class, 'updateBookingStatus']);
Route::get('/admin/reviews', [AdminController::class, 'reviewsPage']);
Route::post('/admin/reviews/{id}/hide', [AdminController::class, 'hideReview']);
Route::post('/admin/reviews/{id}/unhide', [AdminController::class, 'unhideReview']);

Route::get('/owner', [OwnerController::class, 'entry']);
Route::get('/owner/login', [OwnerController::class, 'loginPage']);
Route::post('/owner/login', [OwnerController::class, 'login']);
Route::post('/owner/logout', [OwnerController::class, 'logout']);
Route::get('/owner/bookings', [OwnerController::class, 'bookingsPage']);
Route::post('/owner/bookings/{id}/status', [OwnerController::class, 'updateStatus']);
Route::post('/owner/services/{id}/price', [OwnerController::class, 'updateService']);
Route::post('/owner/workshop/image', [OwnerController::class, 'updateWorkshopImage']);
Route::post('/owner/reviews/{id}/reply', [OwnerController::class, 'replyReview']);
Route::post('/owner/telegram/generate', [OwnerController::class, 'generateTelegramLinkCode']);
Route::post('/owner/telegram/check', [OwnerController::class, 'checkTelegramLink']);
Route::post('/owner/telegram/disconnect', [OwnerController::class, 'disconnectTelegram']);
